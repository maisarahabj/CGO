import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../navigation/services/navigation_service.dart';

/// Compact, expandable turn-by-turn panel shown at the top of an active route.
class HomeRouteInstructionsPanel extends StatefulWidget {
  const HomeRouteInstructionsPanel({
    required this.instructions,
    required this.onStopPressed,
    this.onNewSearchPressed,
    this.onSchedulePressed,
    this.onExpandedChanged,
    super.key,
  });

  static const double instructionRowHeight = 58;
  static const int collapsedVisibleInstructionRows = 2;
  static const int expandedVisibleInstructionRows = 3;
  static const double collapsedPanelChromeHeight = 40;
  static const double expandedPanelChromeHeight = 145;

  final List<NavigationInstruction> instructions;
  final VoidCallback onStopPressed;
  final VoidCallback? onNewSearchPressed;
  final VoidCallback? onSchedulePressed;
  final ValueChanged<bool>? onExpandedChanged;

  @override
  State<HomeRouteInstructionsPanel> createState() =>
      _HomeRouteInstructionsPanelState();
}

class _HomeRouteInstructionsPanelState
    extends State<HomeRouteInstructionsPanel> {
  static const Color _campusBlue = Color(0xFF2A77B4);
  static const Color _subtitleColor = Color(0xFF5B5B5B);
  static const Duration _resizeDuration = Duration(milliseconds: 240);

  bool _isExpanded = false;
  double _verticalDragDistance = 0;

  void _setExpanded(bool value) {
    if (_isExpanded == value) return;

    setState(() {
      _isExpanded = value;
    });

    if (value) {
      widget.onExpandedChanged?.call(true);
      return;
    }

    // Keep the larger WebView shield until the collapse animation finishes.
    Future<void>.delayed(_resizeDuration, () {
      if (mounted && !_isExpanded) {
        widget.onExpandedChanged?.call(false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.instructions.isEmpty) return const SizedBox.shrink();

    final visibleInstructions = _isExpanded
        ? widget.instructions
        : widget.instructions
              .take(HomeRouteInstructionsPanel.collapsedVisibleInstructionRows)
              .toList(growable: false);

    return Material(
      color: Colors.white,
      elevation: 7,
      shadowColor: const Color(0x26000000),
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
      clipBehavior: Clip.antiAlias,
      child: AnimatedSize(
        duration: _resizeDuration,
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragStart: (_) {
            _verticalDragDistance = 0;
          },
          onVerticalDragUpdate: (details) {
            _verticalDragDistance += details.delta.dy;
          },
          onVerticalDragEnd: (details) {
            final velocity = details.primaryVelocity ?? 0;

            if (_verticalDragDistance > 26 || velocity > 120) {
              _setExpanded(true);
            } else if (_verticalDragDistance < -26 || velocity < -120) {
              _setExpanded(false);
            }

            _verticalDragDistance = 0;
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 5),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: HomeRouteInstructionsPanel.instructionRowHeight *
                        (_isExpanded
                            ? HomeRouteInstructionsPanel
                                  .expandedVisibleInstructionRows
                            : HomeRouteInstructionsPanel
                                  .collapsedVisibleInstructionRows),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: _isExpanded
                        ? const BouncingScrollPhysics()
                        : const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: visibleInstructions.length,
                    itemBuilder: (context, index) {
                      return _InstructionRow(
                        instruction: visibleInstructions[index],
                        isLast: index == visibleInstructions.length - 1,
                      );
                    },
                  ),
                ),
                if (_isExpanded) ...[
                  const SizedBox(height: 10),
                  _NewRouteSearchField(
                    onPressed: widget.onNewSearchPressed,
                  ),
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 40,
                          child: FilledButton(
                            onPressed: widget.onStopPressed,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFE82042),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.zero,
                              textStyle: const TextStyle(
                                fontFamily: 'Raleway',
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            child: const Text('Stop'),
                          ),
                        ),
                      ),
                      if (widget.onSchedulePressed != null) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: SizedBox(
                            height: 40,
                            child: OutlinedButton(
                              onPressed: widget.onSchedulePressed,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _campusBlue,
                                side: const BorderSide(color: _campusBlue),
                                padding: EdgeInsets.zero,
                                textStyle: const TextStyle(
                                  fontFamily: 'Raleway',
                                  fontSize: 19,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              child: const Text('Room Schedule'),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
                Semantics(
                  label: _isExpanded
                      ? 'Drag upward to collapse route instructions'
                      : 'Drag downward to expand route instructions',
                  child: Padding(
                    padding: const EdgeInsets.only(top: 13, bottom: 8),
                    child: Center(
                      child: Container(
                        width: 92,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFB4B8BC),
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NewRouteSearchField extends StatelessWidget {
  const _NewRouteSearchField({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
          side: const BorderSide(
            color: _HomeRouteInstructionsPanelState._campusBlue,
            width: 1.7,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(25),
          onTap: onPressed,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  size: 25,
                  color: Color(0xFFABB4BF),
                ),
                SizedBox(width: 10),
                Text(
                  'New search',
                  style: TextStyle(
                    fontFamily: 'RobotoCondensed',
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF9AA3AC),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InstructionRow extends StatelessWidget {
  const _InstructionRow({required this.instruction, required this.isLast});

  final NavigationInstruction instruction;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final detail = instruction.subtitle?.trim();

    return SizedBox(
      height: HomeRouteInstructionsPanel.instructionRowHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 58,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (!isLast)
                  const Positioned(
                    top: 42,
                    bottom: 0,
                    child: SizedBox(
                      width: 1,
                      child: ColoredBox(color: Color(0xFFD3DCE7)),
                    ),
                  ),
                Container(
                  width: 46,
                  height: 46,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8EDF4),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: _InstructionIcon(type: instruction.type),
                ),
              ],
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  instruction.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Raleway',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    height: 1.05,
                    color: Color(0xFF2A77B4),
                  ),
                ),
                if (detail != null && detail.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'RobotoCondensed',
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      height: 1.05,
                      color: _HomeRouteInstructionsPanelState._subtitleColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InstructionIcon extends StatelessWidget {
  const _InstructionIcon({required this.type});

  static const String _iconRoot = 'assets/features/navigation/icons';

  final NavigationInstructionType type;

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF1667A7);

    if (type == NavigationInstructionType.elevator) {
      return SvgPicture.asset(
        '$_iconRoot/elevator.svg',
        width: 24,
        height: 24,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      );
    }

    if (type == NavigationInstructionType.stairs) {
      return Icon(Icons.stairs_rounded, size: 23, color: color);
    }

    if (type == NavigationInstructionType.arrive) {
      return Icon(Icons.location_on_outlined, size: 23, color: color);
    }

    if (type == NavigationInstructionType.uTurn) {
      return Icon(Icons.u_turn_left_rounded, size: 23, color: color);
    }

    final angle = switch (type) {
      NavigationInstructionType.left => -math.pi / 2,
      NavigationInstructionType.right => math.pi / 2,
      NavigationInstructionType.slightLeft => -math.pi / 4,
      NavigationInstructionType.slightRight => math.pi / 4,
      _ => 0.0,
    };

    return Transform.rotate(
      angle: angle,
      child: SvgPicture.asset(
        '$_iconRoot/step_arrow.svg',
        width: 19,
        height: 24,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      ),
    );
  }
}
