import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../app/app_routes.dart';
import '../../../core/constants/app_assets.dart';
import '../../../shared/widgets/campus_navigation_drawer.dart';
import '../../navigation/controllers/navigation_controller.dart';
import '../../navigation/models/destination_model.dart';
import '../../navigation/models/node_model.dart';
import '../../profile/models/profile_model.dart';
import '../models/ongoing_class_model.dart';
import '../widgets/home_floor_selector.dart';
import '../widgets/home_spline_map.dart';
import '../widgets/home_navigation_panel.dart';
import '../widgets/home_route_instructions_panel.dart';
import '../widgets/home_route_summary_panel.dart';
import '../widgets/home_side_controls.dart';
import '../widgets/ongoing_class_card.dart';

enum HomeAccessMode { registeredUser, guest }

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    required this.accessMode,
    required this.onSessionAction,
    this.profile,
    this.ongoingClass,
    this.nextClasses = const [],
    this.mapContent,
    this.unreadNotificationCount = 0,
    this.onNotificationRefresh,
    this.onScheduleRefresh,
    this.initialDestinationNodeId,
    super.key,
  });

  final HomeAccessMode accessMode;

  /// Optional navigation destination supplied by another feature,
  /// such as Timetable -> Navigate Now.

  /// Logs out a registered user or returns a guest to the login screen.
  final Future<void> Function() onSessionAction;

  /// Supabase profile belonging to the signed-in user.
  final ProfileModel? profile;

  /// The class currently in progress, when one exists.
  final OngoingClassModel? ongoingClass;

  /// The registered user's nearest upcoming saved classes.
  final List<OngoingClassModel> nextClasses;

  /// Pass the real Spline or floor-map widget here when it is ready.
  final Widget? mapContent;

  final int unreadNotificationCount;

  final Future<void> Function()? onNotificationRefresh;
  final Future<void> Function()? onScheduleRefresh;
  final String? initialDestinationNodeId;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const List<String> _floors = ['L9', 'L8', 'L6', 'L3', 'L1', 'G'];
  static const double _navigationPanelBottomOffset = -10;

  final TextEditingController _currentLocationController =
      TextEditingController();
  final FocusNode _currentLocationFocusNode = FocusNode();
  final TextEditingController _destinationController = TextEditingController();
  final FocusNode _destinationFocusNode = FocusNode();
  late final NavigationController _navigationController;
  String _selectedFloor = 'L8';
  int _floorSelectionRequest = 0;
  bool _isNavigationPanelExpanded = false;
  bool _areRouteInstructionsExpanded = false;
  String? _dismissedTimetableId;
  bool _initialDestinationApplied = false;
  Timer? _messageBannerTimer;

  bool get _isAccessibilityEnabled {
    return _navigationController.accessibleOnly;
  }

  bool get _isRegisteredUser {
    return widget.accessMode == HomeAccessMode.registeredUser;
  }

  String get _activeSearchQuery {
    if (_currentLocationFocusNode.hasFocus) {
      return _currentLocationController.text.trim();
    }

    if (_destinationFocusNode.hasFocus) {
      return _destinationController.text.trim();
    }

    return '';
  }

  bool get _isSearchActive {
    return _navigationController.isReady && _activeSearchQuery.isNotEmpty;
  }

  List<DestinationModel> get _searchSuggestions {
    if (!_isSearchActive) return const [];

    return _navigationController.searchDestinations(
      _activeSearchQuery,
      limit: 4,
    );
  }

  bool get _isPanelVisuallyExpanded {
    return _isNavigationPanelExpanded || _isSearchActive;
  }

  bool get _showOngoingClassReminder {
    final currentClass = widget.ongoingClass;

    return _isRegisteredUser &&
        !_isPanelVisuallyExpanded &&
        currentClass != null &&
        currentClass.timetableId != _dismissedTimetableId;
  }

  bool get _showMapDismissLayer {
    return _isNavigationPanelExpanded ||
        _currentLocationFocusNode.hasFocus ||
        _destinationFocusNode.hasFocus;
  }

  @override
  void initState() {
    super.initState();
    _navigationController = NavigationController()
      ..addListener(_handleNavigationStateChanged);
    _currentLocationController.addListener(_handleSearchTextChanged);
    _destinationController.addListener(_handleSearchTextChanged);
    _currentLocationFocusNode.addListener(_handleLocationFocusChanged);
    _destinationFocusNode.addListener(_handleLocationFocusChanged);
    unawaited(_loadNavigationGraph());
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    final previousId = oldWidget.ongoingClass?.timetableId;
    final nextId = widget.ongoingClass?.timetableId;

    if (previousId != nextId && nextId != _dismissedTimetableId) {
      _dismissedTimetableId = null;
    }

    if (!_isRegisteredUser && _isNavigationPanelExpanded) {
      _isNavigationPanelExpanded = false;
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    _messageBannerTimer?.cancel();

    final messenger = ScaffoldMessenger.of(context);

    messenger
      ..hideCurrentSnackBar()
      ..hideCurrentMaterialBanner()
      ..showMaterialBanner(
        MaterialBanner(
          backgroundColor: const Color(0xFFFFF4E5),
          leading: const Icon(Icons.info_outline, color: Color(0xFFB86B00)),
          content: Text(
            message,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF333333),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _messageBannerTimer?.cancel();
                messenger.hideCurrentMaterialBanner();
              },
              child: const Text(
                'DISMISS',
                style: TextStyle(
                  color: Color(0xFF2A77B4),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );

    _messageBannerTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
      }
    });
  }

  Future<void> _setAccessibility(bool value) async {
    if (_navigationController.accessibleOnly == value) return;

    // Only reroute automatically when the user already had an active route.
    // Merely selecting a current location and destination should not start
    // navigation just because the accessibility preference changed.
    final hadActiveRoute = _navigationController.routeResult != null;

    // This updates the controller's routing mode and clears any route that was
    // calculated under the previous accessibility setting.
    _navigationController.setAccessibleOnly(value);

    if (!hadActiveRoute) return;

    // Recalculate from a fresh Supabase snapshot so an administrator's latest
    // route closure is also respected while accessibility mode changes.
    final result = await _navigationController.refreshGraphAndCalculateRoute();

    if (!mounted) return;

    if (result == null) {
      _showMessage(
        _navigationController.message ??
            'CampusGO could not recalculate the route.',
      );
      return;
    }

    debugPrint(
      'CampusGO route recalculated after accessibility change: '
      '${value ? 'ON' : 'OFF'}.',
    );
    debugPrint('CampusGO route node IDs: ${result.nodeIds.join(' -> ')}');
    debugPrint('CampusGO route edge IDs: ${result.edgeIds.join(' -> ')}');
    debugPrint('CampusGO route total cost: ${result.totalCost}');
  }

  void _closeDrawerThen(VoidCallback action) {
    Navigator.of(context).pop();
    action();
  }

  void _selectFloor(String floor) {
    setState(() {
      _selectedFloor = floor;
      _floorSelectionRequest++;
    });
  }

  /// Converts the selected node's Supabase floor reference into the exact
  /// Spline floor-object name used by window.selectFloor().
  ///
  /// Most CampusGO rows already store values such as L6 and L9. The graph and
  /// node-ID fallbacks keep camera focusing reliable if a database later uses
  /// an internal floor ID such as FLOOR_6 instead.
  String? _cameraFloorForLocation(DestinationModel location) {
    return _cameraFloorForNode(location.node);
  }

  String? _cameraFloorForNode(NodeModel node) {
    final storedFloorId = node.floorId?.trim();

    if (storedFloorId != null && storedFloorId.isNotEmpty) {
      final normalizedFloorId = storedFloorId.toUpperCase();

      if (_floors.contains(normalizedFloorId)) {
        return normalizedFloorId;
      }

      final graph = _navigationController.graph;

      if (graph != null) {
        for (final floor in graph.floors) {
          if (floor.floorId.trim().toUpperCase() != normalizedFloorId) {
            continue;
          }

          final levelNumber = floor.levelNumber;

          if (levelNumber != null) {
            final cameraFloor = levelNumber == 0 ? 'G' : 'L$levelNumber';

            if (_floors.contains(cameraFloor)) {
              return cameraFloor;
            }
          }
        }
      }

      if (normalizedFloorId == 'G' || normalizedFloorId.contains('GROUND')) {
        return 'G';
      }

      final levelMatch = RegExp(r'\d+').firstMatch(normalizedFloorId);
      final levelNumber = levelMatch == null
          ? null
          : int.tryParse(levelMatch.group(0)!);

      if (levelNumber != null) {
        final cameraFloor = levelNumber == 0 ? 'G' : 'L$levelNumber';

        if (_floors.contains(cameraFloor)) {
          return cameraFloor;
        }
      }
    }

    final normalizedNodeId = node.nodeId.trim().toUpperCase();

    for (final floor in _floors) {
      if (normalizedNodeId == floor ||
          normalizedNodeId.startsWith('${floor}_') ||
          normalizedNodeId.startsWith('${floor}N')) {
        return floor;
      }
    }

    return null;
  }

  /// Floors that should remain visible while navigation is active.
  ///
  /// CampusGO intentionally keeps only the two endpoint floors visible:
  /// the user's current-location floor and the destination floor. Intermediate
  /// floors that Dijkstra passes through are hidden. Route edges remain visible
  /// because they are controlled separately from the Spline floor groups.
  Set<String> _navigationEndpointFloors() {
    final endpointFloors = <String>{};

    final currentLocation = _navigationController.currentLocation;
    if (currentLocation != null) {
      final currentFloor = _cameraFloorForLocation(currentLocation);
      if (currentFloor != null) {
        endpointFloors.add(currentFloor);
      }
    }

    final destination = _navigationController.destination;
    if (destination != null) {
      final destinationFloor = _cameraFloorForLocation(destination);
      if (destinationFloor != null) {
        endpointFloors.add(destinationFloor);
      }
    }

    return endpointFloors;
  }

  void _focusMapOnLocation(
    DestinationModel location, {
    required String reason,
  }) {
    final floor = _cameraFloorForLocation(location);

    if (floor == null) {
      debugPrint(
        'CampusGO camera floor unresolved for ${location.nodeId} '
        '(floor_id: ${location.floorId}, reason: $reason).',
      );
      return;
    }

    debugPrint(
      'CampusGO camera requesting $floor for ${location.nodeId} '
      '(reason: $reason).',
    );
    _selectFloor(floor);
  }

  /// Recenter must return to the floor containing the user's ORIGINAL/current
  /// start location for the navigation session, not whichever floor happens
  /// to be selected right now. Falling back to the destination, and then to
  /// a same-floor reselect, keeps the button useful even before a route has
  /// been calculated.
  void _handleRecenterPressed() {
    final startLocation = _navigationController.currentLocation;

    if (startLocation != null) {
      _focusMapOnLocation(
        startLocation,
        reason: 'recenter button; return to current location',
      );
      return;
    }

    final destination = _navigationController.destination;

    if (destination != null) {
      _focusMapOnLocation(
        destination,
        reason: 'recenter button; no current location set, using destination',
      );
      return;
    }

    // Nothing selected yet: still force the Spline camera back onto the
    // currently selected floor's saved view (same-floor reselect).
    _selectFloor(_selectedFloor);
  }

  void _handleLocationFocusChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _handleNavigationStateChanged() {
    if (mounted) {
      setState(() {
        if (_navigationController.routeResult == null) {
          _areRouteInstructionsExpanded = false;
        }
      });
    }
  }

  void _handleInstructionExpansionChanged(bool isExpanded) {
    if (!mounted || _areRouteInstructionsExpanded == isExpanded) return;

    setState(() {
      _areRouteInstructionsExpanded = isExpanded;
    });
  }

  void _handleSearchTextChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadNavigationGraph() async {
    await _navigationController.loadGraph();

    if (!mounted) {
      return;
    }

    if (!_navigationController.isReady) {
      _showMessage(
        _navigationController.message ??
            'CampusGO could not load its navigation locations.',
      );
      return;
    }

    _applyInitialDestination();
  }

  void _applyInitialDestination() {
    if (_initialDestinationApplied) {
      return;
    }

    _initialDestinationApplied = true;

    final requestedNodeId = widget.initialDestinationNodeId?.trim();

    if (requestedNodeId == null || requestedNodeId.isEmpty) {
      return;
    }

    DestinationModel? destination;

    for (final item in _navigationController.destinations) {
      if (item.nodeId == requestedNodeId) {
        destination = item;
        break;
      }
    }

    if (destination == null) {
      _showMessage('Navigation is not available for this room.');
      return;
    }

    _selectDestination(destination);

    if (_isRegisteredUser) {
      setState(() {
        _isNavigationPanelExpanded = true;
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      _currentLocationFocusNode.requestFocus();
    });
  }

  Future<void> _handleQrPressed() async {
    _collapseNavigationPanel();

    final node = await Navigator.of(
      context,
    ).pushNamed<NodeModel>(AppRoutes.qrScanner);

    if (!mounted || node == null) return;

    // From this point onward QR and manual selection use the same state path.
    // The scanner returns a real NodeModel, then HomeScreen wraps it in the
    // same DestinationModel that manual search already uses.
    final location = DestinationModel(node: node);
    _selectCurrentLocation(location);
    _showMessage('Current location set to ${location.name}.');
  }

  void _selectCurrentLocation(DestinationModel location) {
    _currentLocationController.value = TextEditingValue(
      text: location.name,
      selection: TextSelection.collapsed(offset: location.name.length),
    );
    _navigationController.selectCurrentLocation(location);
    _focusMapOnLocation(location, reason: 'current location selected');
    _currentLocationFocusNode.unfocus();
  }

  void _selectDestination(DestinationModel destination) {
    _destinationController.value = TextEditingValue(
      text: destination.name,
      selection: TextSelection.collapsed(offset: destination.name.length),
    );
    _navigationController.selectDestination(destination);
    _focusMapOnLocation(destination, reason: 'destination selected');
    _destinationFocusNode.unfocus();
  }

  void _selectSearchSuggestion(DestinationModel suggestion) {
    if (_currentLocationFocusNode.hasFocus) {
      _selectCurrentLocation(suggestion);
      return;
    }

    if (_destinationFocusNode.hasFocus) {
      _selectDestination(suggestion);
    }
  }

  Future<void> _startNavigation() async {
    _currentLocationFocusNode.unfocus();
    _destinationFocusNode.unfocus();

    // The graph used for destination search is cached, but route availability
    // is operational data. Reload active edges before every explicit Navigate
    // action so an admin closure affects the next Dijkstra calculation.
    final result = await _navigationController.refreshGraphAndCalculateRoute();

    if (!mounted) return;

    if (result == null) {
      _showMessage(
        _navigationController.message ??
            'CampusGO could not calculate a route.',
      );
      return;
    }

    debugPrint('CampusGO route node IDs: ${result.nodeIds.join(' -> ')}');
    debugPrint('CampusGO route edge IDs: ${result.edgeIds.join(' -> ')}');
    debugPrint('CampusGO route total cost: ${result.totalCost}');

    final startLocation = _navigationController.currentLocation;

    if (startLocation != null) {
      _focusMapOnLocation(
        startLocation,
        reason: 'route calculated; return to route start',
      );
    }

    _collapseNavigationPanel();
  }

  void _endNavigation() {
    _navigationController.clearRoute();
    _collapseNavigationPanel();
  }

  bool _ensureNavigationReady() {
    if (_navigationController.isReady) return true;

    _showMessage(
      _navigationController.isLoadingGraph
          ? 'Navigation locations are still loading.'
          : _navigationController.message ??
                'Navigation locations are unavailable.',
    );
    return false;
  }

  void _handleCurrentLocationPressed() {
    if (!_ensureNavigationReady()) return;
    _currentLocationFocusNode.requestFocus();
  }

  void _dismissOngoingClass() {
    final currentClass = widget.ongoingClass;

    if (currentClass == null) return;

    setState(() {
      _dismissedTimetableId = currentClass.timetableId;
    });
  }

  void _handleDestinationPressed() {
    if (!_ensureNavigationReady()) return;

    if (!_isRegisteredUser || _isNavigationPanelExpanded) {
      _destinationFocusNode.requestFocus();
      return;
    }

    _currentLocationFocusNode.unfocus();
    setState(() {
      _isNavigationPanelExpanded = true;
    });
  }

  void _handleDestinationSwipeUp() {
    // Guests go directly to destination typing, so their panel does not expand.
    if (!_isRegisteredUser || _isNavigationPanelExpanded) return;

    _currentLocationFocusNode.unfocus();
    _destinationFocusNode.unfocus();
    setState(() {
      _isNavigationPanelExpanded = true;
    });
  }

  void _collapseNavigationPanel() {
    _currentLocationFocusNode.unfocus();
    _destinationFocusNode.unfocus();

    if (!_isNavigationPanelExpanded || !mounted) return;

    setState(() {
      _isNavigationPanelExpanded = false;
    });
  }

  Future<void> _openTimetable() async {
    await Navigator.of(context).pushNamed(AppRoutes.timetable);

    if (!mounted) return;

    await widget.onScheduleRefresh?.call();
  }

  Future<void> _navigateToClass(OngoingClassModel scheduledClass) async {
    if (!_ensureNavigationReady()) return;

    final roomNodeId = scheduledClass.roomNodeId.trim();

    if (roomNodeId.isEmpty) {
      _showMessage('Navigation is not available for this classroom yet.');
      return;
    }

    DestinationModel? destination;

    for (final item in _navigationController.destinations) {
      if (item.nodeId == roomNodeId) {
        destination = item;
        break;
      }
    }

    if (destination == null) {
      _showMessage('Navigation is not available for this classroom yet.');
      return;
    }

    _selectDestination(destination);

    // If the user already has a current location, "Navigate Now" can start
    // the route immediately using the existing Dijkstra pipeline.
    if (_navigationController.currentLocation != null) {
      await _startNavigation();
      return;
    }

    // Otherwise keep the selected class as the destination and ask only for
    // the missing current location. The user can type it or use the QR button.
    if (!_isNavigationPanelExpanded) {
      setState(() {
        _isNavigationPanelExpanded = true;
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _currentLocationFocusNode.requestFocus();
    });

    _showMessage(
      '${scheduledClass.roomName} is set as your destination. '
      'Select or scan your current location.',
    );
  }

  @override
  void dispose() {
    _messageBannerTimer?.cancel();
    _navigationController
      ..removeListener(_handleNavigationStateChanged)
      ..dispose();
    _currentLocationFocusNode
      ..removeListener(_handleLocationFocusChanged)
      ..dispose();
    _currentLocationController
      ..removeListener(_handleSearchTextChanged)
      ..dispose();
    _destinationFocusNode
      ..removeListener(_handleLocationFocusChanged)
      ..dispose();
    _destinationController
      ..removeListener(_handleSearchTextChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomSafeArea = MediaQuery.paddingOf(context).bottom;
    final isSearchActive = _isSearchActive;
    final searchSuggestions = _searchSuggestions;
    final isPanelVisuallyExpanded = _isPanelVisuallyExpanded;
    final activeRoute = _navigationController.routeResult;
    final activeDestination = _navigationController.destination;
    final hasActiveRoute = activeRoute != null && activeDestination != null;
    final activeRouteFloors = _navigationEndpointFloors();
    final visibleFloorSelectorFloors =
        hasActiveRoute && activeRouteFloors.isNotEmpty
        ? _floors.where(activeRouteFloors.contains).toList(growable: false)
        : _floors;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        // The SafeArea keeps instruction text below the clock and Dynamic
        // Island, while this background extends the white panel behind them.
        backgroundColor: hasActiveRoute
            ? Colors.white
            : const Color(0xFFE8E8E8),
        drawerScrimColor: const Color(0x3D000000),
        drawer: CampusNavigationDrawer(
          unreadNotificationCount: widget.unreadNotificationCount,
          isRegisteredUser: _isRegisteredUser,
          profile: widget.profile,
          onProfilePressed: _isRegisteredUser
              ? () {
                  _closeDrawerThen(() {
                    Navigator.of(context).pushNamed(AppRoutes.editProfile);
                  });
                }
              : null,
          isAccessibilityEnabled: _isAccessibilityEnabled,
          onNotificationPressed: () async {
            final navigator = Navigator.of(context);

            navigator.pop();

            await navigator.pushNamed(AppRoutes.notifications);

            if (mounted) {
              await widget.onNotificationRefresh?.call();
            }
          },
          onTimetablePressed: () {
            _closeDrawerThen(() {
              unawaited(_openTimetable());
            });
          },
          onSettingsPressed: () {
            _closeDrawerThen(() {
              Navigator.of(context).pushNamed(AppRoutes.settings);
            });
          },
          onAccessibilityChanged: _setAccessibility,
          onHelpPressed: () {
            _closeDrawerThen(() {
              Navigator.of(context).pushNamed(AppRoutes.support);
            });
          },
          onSessionAction: widget.onSessionAction,
        ),
        body: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final collapsedPanelHeight = 145.0 + bottomSafeArea;
              final routeSummaryPanelHeight = 126.0 + bottomSafeArea;
              final expandedPanelHeight = (constraints.maxHeight * 0.64)
                  .clamp(collapsedPanelHeight, constraints.maxHeight - 64)
                  .toDouble();
              final guestSearchRows = math.max(1, searchSuggestions.length);
              final guestSearchMaximumHeight = math.max(
                collapsedPanelHeight,
                constraints.maxHeight - 64,
              );
              final guestSearchPanelHeight =
                  (collapsedPanelHeight + 8 + (guestSearchRows * 58))
                      .clamp(collapsedPanelHeight, guestSearchMaximumHeight)
                      .toDouble();
              final panelHeight = hasActiveRoute
                  ? routeSummaryPanelHeight
                  : !isPanelVisuallyExpanded
                  ? collapsedPanelHeight
                  : _isRegisteredUser
                  ? expandedPanelHeight
                  : guestSearchPanelHeight;
              final maximumSideBottom = math.max(
                12.0,
                constraints.maxHeight - 225,
              );
              final sideControlsBottom = math.min(
                panelHeight + _navigationPanelBottomOffset + 12,
                maximumSideBottom,
              );
              final instructionCount =
                  _navigationController.instructions.length;
              final maximumInstructionRows = _areRouteInstructionsExpanded
                  ? 6
                  : 2;
              final visibleInstructionRows = math.min(
                instructionCount,
                maximumInstructionRows,
              );
              final routeInstructionPanelHeight =
                  hasActiveRoute && instructionCount > 0
                  ? (visibleInstructionRows * 58.0) +
                        (_areRouteInstructionsExpanded ? 85.0 : 40.0)
                  : 0.0;

              return Stack(
                children: [
                  Positioned.fill(
                    child:
                        widget.mapContent ??
                        HomeSplineMap(
                          selectedFloor: _selectedFloor,
                          selectionRequest: _floorSelectionRequest,
                          topGestureExclusionHeight:
                              routeInstructionPanelHeight,
                          visibleRouteEdgeIds:
                              _navigationController.routeResult?.edgeIds
                                  .toSet() ??
                              const <String>{},
                          // Empty means normal browsing: every floor remains
                          // visible. During navigation, only the current-location
                          // floor and destination floor remain visible. Route
                          // edges are controlled separately and stay visible.
                          visibleFloorNames: hasActiveRoute
                              ? activeRouteFloors
                              : const <String>{},
                          // Selected endpoints are useful before navigation
                          // begins. Route edges remain empty until the user
                          // explicitly calculates the route.
                          routeStartNode:
                              _navigationController.currentLocation?.node,
                          routeDestinationNode:
                              _navigationController.destination?.node,
                        ),
                  ),
                  if (_showMapDismissLayer)
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _collapseNavigationPanel,
                        child: const SizedBox.expand(),
                      ),
                    ),
                  if (!hasActiveRoute && !_showOngoingClassReminder)
                    Positioned(
                      top: 6,
                      left: 7,
                      child: Builder(
                        builder: (scaffoldContext) {
                          return _MenuButton(
                            onPressed: () {
                              _collapseNavigationPanel();
                              Scaffold.of(scaffoldContext).openDrawer();
                            },
                          );
                        },
                      ),
                    ),
                  if (!hasActiveRoute && _showOngoingClassReminder)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: OngoingClassCard(
                        ongoingClass: widget.ongoingClass!,
                        onNavigatePressed: () {
                          _navigateToClass(widget.ongoingClass!);
                        },
                        onDismissed: _dismissOngoingClass,
                      ),
                    ),
                  if (hasActiveRoute &&
                      _navigationController.instructions.isNotEmpty)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: HomeRouteInstructionsPanel(
                        key: ValueKey(
                          'route-instructions-'
                          '${activeRoute.nodeIds.first}-'
                          '${activeRoute.nodeIds.last}',
                        ),
                        instructions: _navigationController.instructions,
                        onStopPressed: _endNavigation,
                        onExpandedChanged: _handleInstructionExpansionChanged,
                        onSchedulePressed: _isRegisteredUser
                            ? () {
                                unawaited(_openTimetable());
                              }
                            : null,
                      ),
                    ),
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutCubic,
                    left: 10,
                    bottom: sideControlsBottom,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        HomeFloorSelector(
                          floors: visibleFloorSelectorFloors,
                          selectedFloor: _selectedFloor,
                          onFloorSelected: _selectFloor,
                        ),
                        const SizedBox(height: 8),
                        HomeSideControls(
                          isAccessibleRouteEnabled: _isAccessibilityEnabled,
                          onAccessibilityPressed: () {
                            _setAccessibility(!_isAccessibilityEnabled);
                          },
                          onRecenterPressed: _handleRecenterPressed,
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: _navigationPanelBottomOffset,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeOutCubic,
                      height: panelHeight,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        child: hasActiveRoute
                            ? HomeRouteSummaryPanel(
                                key: const ValueKey('route-summary-panel'),
                                destination: activeDestination,
                                routeResult: activeRoute,
                                bottomSafeArea: bottomSafeArea,
                                onClosePressed: _endNavigation,
                              )
                            : HomeNavigationPanel(
                                key: const ValueKey('navigation-input-panel'),
                                isExpanded: isPanelVisuallyExpanded,
                                isRegisteredUser: _isRegisteredUser,
                                bottomSafeArea: bottomSafeArea,
                                ongoingClass: widget.ongoingClass,
                                nextClasses: widget.nextClasses,
                                currentLocationController:
                                    _currentLocationController,
                                currentLocationFocusNode:
                                    _currentLocationFocusNode,
                                destinationController: _destinationController,
                                destinationFocusNode: _destinationFocusNode,
                                isDestinationEditable:
                                    !_isRegisteredUser ||
                                    _isNavigationPanelExpanded,
                                isSearchActive: isSearchActive,
                                searchSuggestions: searchSuggestions,
                                onSearchSuggestionSelected:
                                    _selectSearchSuggestion,
                                onCurrentLocationTextChanged:
                                    _navigationController
                                        .currentLocationTextChanged,
                                onDestinationTextChanged: _navigationController
                                    .destinationTextChanged,
                                canStartNavigation:
                                    _navigationController.canCalculateRoute,
                                isNavigationLoading:
                                    _navigationController.isLoadingGraph,
                                onCurrentLocationPressed:
                                    _handleCurrentLocationPressed,
                                onQrPressed: _handleQrPressed,
                                onDestinationPressed: _handleDestinationPressed,
                                onStartNavigationPressed: _startNavigation,
                                onDestinationSwipeUp: _handleDestinationSwipeUp,
                                onDestinationSwipeDown:
                                    _collapseNavigationPanel,
                                onBackgroundPressed: _collapseNavigationPanel,
                                onNavigatePressed: _navigateToClass,
                                onViewAllPressed: () {
                                  _collapseNavigationPanel();
                                  unawaited(_openTimetable());
                                },
                              ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Open menu',
      onPressed: onPressed,
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints.tightFor(width: 42, height: 42),
      icon: SvgPicture.asset(AppAssets.hamburger, width: 25, height: 19),
    );
  }
}
