import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';
import '../../../shared/widgets/campus_navigation_drawer.dart';
import '../../profile/models/profile_model.dart';
import '../models/ongoing_class_model.dart';
import '../widgets/home_floor_selector.dart';
import '../widgets/home_map_placeholder.dart';
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

  final TextEditingController _destinationController = TextEditingController();
  final FocusNode _destinationFocusNode = FocusNode();
  String _selectedFloor = 'L9';
  bool _isAccessibilityEnabled = false;
  bool _isNavigationPanelExpanded = false;
  String? _dismissedTimetableId;

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
    return _isNavigationPanelExpanded || _destinationFocusNode.hasFocus;
  }

  @override
  void initState() {
    super.initState();
    _destinationFocusNode.addListener(_handleDestinationFocusChanged);
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
    setState(() {
      _isAccessibilityEnabled = value;
    });
  }

  void _closeDrawerThen(VoidCallback action) {
    Navigator.of(context).pop();
    action();
  }

  void _selectFloor(String floor) {
    setState(() {
      _selectedFloor = floor;
    });
  }

  void _handleDestinationFocusChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _dismissOngoingClass() {
    final currentClass = widget.ongoingClass;

    if (currentClass == null) return;

    setState(() {
      _dismissedTimetableId = currentClass.timetableId;
    });
  }

  void _handleDestinationPressed() {
    if (!_isRegisteredUser || _isNavigationPanelExpanded) {
      _destinationFocusNode.requestFocus();
      return;
    }

    setState(() {
      _isNavigationPanelExpanded = true;
    });
  }

  void _handleDestinationSwipeUp() {
    // Guests go directly to destination typing, so their panel does not expand.
    if (!_isRegisteredUser || _isNavigationPanelExpanded) return;

    _destinationFocusNode.unfocus();
    setState(() {
      _isNavigationPanelExpanded = true;
    });
  }

  void _collapseNavigationPanel() {
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
    _destinationFocusNode
      ..removeListener(_handleDestinationFocusChanged)
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
          isAccessibilityEnabled: _isAccessibilityEnabled,
          onNotificationPressed: () {
            _closeDrawerThen(() {
              _showMessage('Notification screen will be connected next.');
            });
          },
          onTimetablePressed: () {
            _closeDrawerThen(() {
              _showMessage('Timetable screen will be connected next.');
            });
          },
          onSettingsPressed: () {
            _closeDrawerThen(() {
              _showMessage('Settings screen will be connected next.');
            });
          },
          onAccessibilityChanged: _setAccessibility,
          onHelpPressed: () {
            _closeDrawerThen(() {
              _showMessage('Help & Feedback will be connected next.');
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
                        HomeMapPlaceholder(selectedFloor: _selectedFloor),
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
                        destinationController: _destinationController,
                        destinationFocusNode: _destinationFocusNode,
                        isDestinationEditable:
                            !_isRegisteredUser || _isNavigationPanelExpanded,
                        onCurrentLocationPressed: () {
                          _collapseNavigationPanel();
                          _showMessage(
                            'Choose or detect the current location here.',
                          );
                        },
                        onQrPressed: () {
                          _collapseNavigationPanel();
                          _showMessage('QR checkpoint scanner opens here.');
                        },
                        onDestinationPressed: _handleDestinationPressed,
                        onDestinationSwipeUp: _handleDestinationSwipeUp,
                        onDestinationSwipeDown: _collapseNavigationPanel,
                        onBackgroundPressed: _collapseNavigationPanel,
                        onNavigatePressed: _navigateToClass,
                        onViewAllPressed: () {
                          _collapseNavigationPanel();
                          _showMessage(
                            'The full timetable screen will open here.',
                          );
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
