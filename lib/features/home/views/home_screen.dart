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
import '../../profile/models/profile_model.dart';
import '../models/ongoing_class_model.dart';
import '../widgets/home_floor_selector.dart';
import '../widgets/home_spline_map.dart';
import '../widgets/home_navigation_panel.dart';
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
    super.key,
  });

  final HomeAccessMode accessMode;

  /// Logs out a registered user or returns a guest to the login screen.
  final Future<void> Function() onSessionAction;

  /// Supabase profile belonging to the signed-in user.
  final ProfileModel? profile;

  /// The class currently in progress, when one exists.
  final OngoingClassModel? ongoingClass;

  /// The registered user's remaining classes today.
  final List<OngoingClassModel> nextClasses;

  /// Pass the real Spline or floor-map widget here when it is ready.
  final Widget? mapContent;

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
  String? _dismissedTimetableId;

  bool get _isAccessibilityEnabled {
    return _navigationController.accessibleOnly;
  }

  bool get _isRegisteredUser {
    return widget.accessMode == HomeAccessMode.registeredUser;
  }

  bool get _showOngoingClassReminder {
    final currentClass = widget.ongoingClass;

    return _isRegisteredUser &&
        !_isNavigationPanelExpanded &&
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
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _setAccessibility(bool value) {
    _navigationController.setAccessibleOnly(value);
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

  void _handleLocationFocusChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _handleNavigationStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadNavigationGraph() async {
    await _navigationController.loadGraph();

    if (!mounted || _navigationController.isReady) return;
    _showMessage(
      _navigationController.message ??
          'CampusGO could not load its navigation locations.',
    );
  }

  Iterable<DestinationModel> _searchLocations(TextEditingValue value) {
    if (!_navigationController.isReady) {
      return const <DestinationModel>[];
    }

    return _navigationController.searchDestinations(value.text);
  }

  void _selectCurrentLocation(DestinationModel location) {
    _navigationController.selectCurrentLocation(location);
    _currentLocationFocusNode.unfocus();
  }

  void _selectDestination(DestinationModel destination) {
    _navigationController.selectDestination(destination);
    _destinationFocusNode.unfocus();
  }

  void _startNavigation() {
    _currentLocationFocusNode.unfocus();
    _destinationFocusNode.unfocus();

    final result = _navigationController.calculateRoute();
    if (result == null) {
      _showMessage(
        _navigationController.message ?? 'CampusGO could not calculate a route.',
      );
      return;
    }

    debugPrint('CampusGO route node IDs: ${result.nodeIds.join(' -> ')}');
    debugPrint('CampusGO route edge IDs: ${result.edgeIds.join(' -> ')}');
    debugPrint('CampusGO route total cost: ${result.totalCost}');

    _collapseNavigationPanel();
    _showMessage(
      'Route ready: ${result.nodeIds.length} nodes, '
      '${result.edgeIds.length} edges, '
      'cost ${result.totalCost.toStringAsFixed(2)}.',
    );
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

  void _navigateToClass(OngoingClassModel scheduledClass) {
    _collapseNavigationPanel();
    _showMessage('Navigation to ${scheduledClass.roomName} will start here.');
  }

  @override
  void dispose() {
    _navigationController
      ..removeListener(_handleNavigationStateChanged)
      ..dispose();
    _currentLocationFocusNode
      ..removeListener(_handleLocationFocusChanged)
      ..dispose();
    _currentLocationController.dispose();
    _destinationFocusNode
      ..removeListener(_handleLocationFocusChanged)
      ..dispose();
    _destinationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomSafeArea = MediaQuery.paddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFE8E8E8),
        drawerScrimColor: const Color(0x3D000000),
        drawer: CampusNavigationDrawer(
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
          onNotificationPressed: () {
            _closeDrawerThen(() {
              Navigator.of(context).pushNamed(AppRoutes.notifications);
            });
          },
          onTimetablePressed: () {
            _closeDrawerThen(() {
              Navigator.of(context).pushNamed(AppRoutes.timetable);
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
              final expandedPanelHeight = (constraints.maxHeight * 0.64)
                  .clamp(collapsedPanelHeight, constraints.maxHeight - 64)
                  .toDouble();
              final panelHeight = _isNavigationPanelExpanded
                  ? expandedPanelHeight
                  : collapsedPanelHeight;
              final maximumSideBottom = math.max(
                12.0,
                constraints.maxHeight - 225,
              );
              final sideControlsBottom = math.min(
                panelHeight + _navigationPanelBottomOffset + 12,
                maximumSideBottom,
              );

              return Stack(
                children: [
                  Positioned.fill(
                    child:
                        widget.mapContent ??
                        HomeSplineMap(
                          selectedFloor: _selectedFloor,
                          selectionRequest: _floorSelectionRequest,
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
                  if (!_showOngoingClassReminder)
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
                  if (_showOngoingClassReminder)
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
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutCubic,
                    left: 10,
                    bottom: sideControlsBottom,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        HomeFloorSelector(
                          floors: _floors,
                          selectedFloor: _selectedFloor,
                          onFloorSelected: _selectFloor,
                        ),
                        const SizedBox(height: 8),
                        HomeSideControls(
                          isAccessibleRouteEnabled: _isAccessibilityEnabled,
                          onAccessibilityPressed: () {
                            _setAccessibility(!_isAccessibilityEnabled);
                          },
                          onRecenterPressed: () {
                            _showMessage('Map recentered.');
                          },
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
                      child: HomeNavigationPanel(
                        isExpanded: _isNavigationPanelExpanded,
                        isRegisteredUser: _isRegisteredUser,
                        bottomSafeArea: bottomSafeArea,
                        ongoingClass: widget.ongoingClass,
                        nextClasses: widget.nextClasses,
                        currentLocationController: _currentLocationController,
                        currentLocationFocusNode: _currentLocationFocusNode,
                        destinationController: _destinationController,
                        destinationFocusNode: _destinationFocusNode,
                        isDestinationEditable:
                            !_isRegisteredUser || _isNavigationPanelExpanded,
                        currentLocationOptionsBuilder: _searchLocations,
                        destinationOptionsBuilder: _searchLocations,
                        onCurrentLocationSelected: _selectCurrentLocation,
                        onDestinationSelected: _selectDestination,
                        onCurrentLocationTextChanged:
                            _navigationController.currentLocationTextChanged,
                        onDestinationTextChanged:
                            _navigationController.destinationTextChanged,
                        canStartNavigation:
                            _navigationController.canCalculateRoute,
                        isNavigationLoading:
                            _navigationController.isLoadingGraph,
                        onCurrentLocationPressed: _handleCurrentLocationPressed,
                        onQrPressed: () {
                          _collapseNavigationPanel();
                          _showMessage('QR checkpoint scanner opens here.');
                        },
                        onDestinationPressed: _handleDestinationPressed,
                        onStartNavigationPressed: _startNavigation,
                        onDestinationSwipeUp: _handleDestinationSwipeUp,
                        onDestinationSwipeDown: _collapseNavigationPanel,
                        onBackgroundPressed: _collapseNavigationPanel,
                        onNavigatePressed: _navigateToClass,
                        onViewAllPressed: () {
                          _collapseNavigationPanel();
                          Navigator.of(context).pushNamed(AppRoutes.timetable);
                        },
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
