import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';

class HomeLocationFields extends StatelessWidget {
  const HomeLocationFields({
    required this.currentLocationController,
    required this.currentLocationFocusNode,
    required this.destinationController,
    required this.destinationFocusNode,
    required this.isDestinationEditable,
    required this.onCurrentLocationPressed,
    required this.onQrPressed,
    required this.onDestinationPressed,
    required this.onDestinationSwipeUp,
    required this.onDestinationSwipeDown,
    super.key,
  });

  final TextEditingController currentLocationController;
  final FocusNode currentLocationFocusNode;
  final TextEditingController destinationController;
  final FocusNode destinationFocusNode;
  final bool isDestinationEditable;
  final VoidCallback onCurrentLocationPressed;
  final VoidCallback onQrPressed;
  final VoidCallback onDestinationPressed;
  final VoidCallback onDestinationSwipeUp;
  final VoidCallback onDestinationSwipeDown;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CurrentLocationField(
          controller: currentLocationController,
          focusNode: currentLocationFocusNode,
          leadingAsset: AppAssets.currentLocation,
          onPressed: onCurrentLocationPressed,
          trailing: IconButton(
            tooltip: 'Scan current-location QR checkpoint',
            onPressed: onQrPressed,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 40, height: 40),
            icon: SvgPicture.asset(
              AppAssets.scanQr,
              width: 32,
              height: 32,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 5),
        _DestinationField(
          controller: destinationController,
          focusNode: destinationFocusNode,
          isEditable: isDestinationEditable,
          onPressed: onDestinationPressed,
          onSwipeUp: onDestinationSwipeUp,
          onSwipeDown: onDestinationSwipeDown,
        ),
      ],
    );
  }
}

class _DestinationField extends StatelessWidget {
  const _DestinationField({
    required this.controller,
    required this.focusNode,
    required this.isEditable,
    required this.onPressed,
    required this.onSwipeUp,
    required this.onSwipeDown,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isEditable;
  final VoidCallback onPressed;
  final VoidCallback onSwipeUp;
  final VoidCallback onSwipeDown;

  void _handleVerticalDragEnd(DragEndDetails details) {
    final verticalVelocity = details.primaryVelocity ?? 0;

    if (verticalVelocity < -150) {
      onSwipeUp();
    } else if (verticalVelocity > 150) {
      onSwipeDown();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 4,
      shadowColor: const Color(0x33000000),
      borderRadius: BorderRadius.circular(28),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        onVerticalDragEnd: _handleVerticalDragEnd,
        child: Container(
          height: 55,
          padding: const EdgeInsets.fromLTRB(20, 0, 17, 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFF2A77B4), width: 1.25),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 27,
                height: 31,
                child: Center(
                  child: SvgPicture.asset(
                    AppAssets.destinationPin,
                    width: 26,
                    height: 30,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: isEditable
                    ? TextField(
                        controller: controller,
                        focusNode: focusNode,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.search,
                        textCapitalization: TextCapitalization.words,
                        maxLines: 1,
                        cursorColor: const Color(0xFF2A77B4),
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1E1E1E),
                          height: 1,
                        ),
                        decoration: const InputDecoration.collapsed(
                          hintText: 'Where to?',
                          hintStyle: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFB8B8B8),
                            height: 1,
                          ),
                        ),
                      )
                    : const Text(
                        'Where to?',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFB8B8B8),
                          height: 1,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurrentLocationField extends StatelessWidget {
  const _CurrentLocationField({
    required this.controller,
    required this.focusNode,
    required this.leadingAsset,
    required this.onPressed,
    this.trailing,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String leadingAsset;
  final VoidCallback onPressed;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 4,
      shadowColor: const Color(0x33000000),
      borderRadius: BorderRadius.circular(28),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: Container(
          height: 55,
          padding: const EdgeInsets.fromLTRB(20, 0, 17, 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFF2A77B4), width: 1.25),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 27,
                height: 31,
                child: Center(
                  child: SvgPicture.asset(
                    leadingAsset,
                    width: 26,
                    height: 30,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.search,
                  textCapitalization: TextCapitalization.words,
                  maxLines: 1,
                  cursorColor: const Color(0xFF2A77B4),
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1E1E1E),
                    height: 1,
                  ),
                  decoration: const InputDecoration.collapsed(
                    hintText: 'Current Location',
                    hintStyle: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFB8B8B8),
                      height: 1,
                    ),
                  ),
                  onSubmitted: (_) => focusNode.unfocus(),
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 6), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}
