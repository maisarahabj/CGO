import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';

class HomeSideControls extends StatelessWidget {
  const HomeSideControls({
    required this.isAccessibleRouteEnabled,
    required this.onAccessibilityPressed,
    required this.onRecenterPressed,
    super.key,
  });

  final bool isAccessibleRouteEnabled;
  final VoidCallback onAccessibilityPressed;
  final VoidCallback onRecenterPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _MapControlButton(
          tooltip: isAccessibleRouteEnabled
              ? 'Disable accessible route'
              : 'Enable accessible route',
          isSelected: isAccessibleRouteEnabled,
          onPressed: onAccessibilityPressed,
          child: SvgPicture.asset(
            AppAssets.wheelchair,
            width: 21,
            height: 26,
            colorFilter: isAccessibleRouteEnabled
                ? const ColorFilter.mode(Colors.white, BlendMode.srcIn)
                : null,
          ),
        ),
        const SizedBox(height: 7),
        _MapControlButton(
          tooltip: 'Recenter map',
          onPressed: onRecenterPressed,
          child: SvgPicture.asset(AppAssets.recenter, width: 24, height: 24),
        ),
      ],
    );
  }
}

class _MapControlButton extends StatelessWidget {
  const _MapControlButton({
    required this.tooltip,
    required this.onPressed,
    required this.child,
    this.isSelected = false,
  });

  final String tooltip;
  final VoidCallback onPressed;
  final Widget child;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? const Color(0xFF2A77B4) : Colors.white,
      elevation: 3,
      shadowColor: const Color(0x30000000),
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(9),
        child: Tooltip(
          message: tooltip,
          child: SizedBox(width: 36, height: 39, child: Center(child: child)),
        ),
      ),
    );
  }
}
