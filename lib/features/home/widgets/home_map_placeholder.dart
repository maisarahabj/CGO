import 'package:flutter/material.dart';

/// Empty background used until the real Spline map is connected.
///
/// This widget deliberately does not draw rooms, paths, or floor geometry.
/// The [selectedFloor] remains part of its contract so the placeholder can be
/// replaced by a floor-aware Spline widget later without changing the home
/// screen structure.
class HomeMapPlaceholder extends StatelessWidget {
  const HomeMapPlaceholder({required this.selectedFloor, super.key});

  final String selectedFloor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Map area for $selectedFloor',
      child: const ColoredBox(
        color: Color(0xFFE8E8E8),
        child: SizedBox.expand(),
      ),
    );
  }
}
