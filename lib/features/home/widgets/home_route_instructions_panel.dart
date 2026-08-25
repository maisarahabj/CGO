import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../navigation/services/navigation_service.dart';

/// Compact, expandable turn-by-turn panel shown at the top of an active route.
class HomeRouteInstructionsPanel extends StatefulWidget {
  const HomeRouteInstructionsPanel({
    required this.instructions,
    required this.onStopPressed,
    this.onSchedulePressed,
    this.onExpandedChanged,
    super.key,
  });

  final List<NavigationInstruction> instructions;
  final VoidCallback onStopPressed;
  final VoidCallback? onSchedulePressed;
  final ValueChanged<bool>? onExpandedChanged;

  @override
  State<HomeRouteInstructionsPanel> createState() =>
      _HomeRouteInstructionsPanelState();
}

class _HomeRouteInstructionsPanelState
    extends State<HomeRouteInstructionsPanel> {
  static const Color _campusBlue = Color(0xFF2A77B4);
  static const Color _subtitleColor = Color(0xFF69747E);
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
        : widget.instructions.take(2).toList(growable: false);

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
                    maxHeight: _isExpanded ? 348 : 116,
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
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 36,
                          child: FilledButton(
                            onPressed: widget.onStopPressed,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFE82042),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.zero,
                              textStyle: const TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            child: const Text('Stop'),
                          ),
                        ),
                      ),
                      if (widget.onSchedulePressed != null) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: 36,
                            child: OutlinedButton(
                              onPressed: widget.onSchedulePressed,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _campusBlue,
                                side: const BorderSide(color: _campusBlue),
                                padding: EdgeInsets.zero,
                                textStyle: const TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
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

class _InstructionRow extends StatelessWidget {
  const _InstructionRow({required this.instruction, required this.isLast});

  final NavigationInstruction instruction;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final detail = instruction.subtitle?.trim();

    return SizedBox(
      height: 58,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 50,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (!isLast)
                  const Positioned(
                    top: 35,
                    bottom: 0,
                    child: SizedBox(
                      width: 1,
                      child: ColoredBox(color: Color(0xFFD3DCE7)),
                    ),
                  ),
                Container(
                  width: 37,
                  height: 37,
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
          const SizedBox(width: 2),
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
                    fontFamily: 'Roboto',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 1.12,
                    color: Color(0xFF2A77B4),
                  ),
                ),
                if (detail != null && detail.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      height: 1.1,
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
