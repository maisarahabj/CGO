import 'package:flutter/material.dart';

import '../../home/widgets/home_floor_selector.dart';
import '../../home/widgets/home_spline_map.dart';

/// Read-only Spline floor viewer used by the administrator dashboard.
///
/// The WebView remains controlled by Flutter so the floor buttons can switch
/// cameras, but pointer input is blocked from reaching Spline. This prevents
/// accidental pan, zoom, orbit, and pinch gestures while the dashboard itself
/// remains vertically scrollable.
class AdminCurrentMap extends StatefulWidget {
  const AdminCurrentMap({super.key});

  @override
  State<AdminCurrentMap> createState() => _AdminCurrentMapState();
}

class _AdminCurrentMapState extends State<AdminCurrentMap> {
  static const List<String> _floors = <String>[
    'L9',
    'L8',
    'L6',
    'L3',
    'L1',
    'G',
  ];

  String _selectedFloor = 'L9';
  int _selectionRequest = 0;

  @override
  void initState() {
    super.initState();

    // HomeSplineMap deliberately preserves Camera_Overview on ordinary app
    // startup. The dashboard is different: it is a floor inspector, so it
    // makes one explicit request for the initial L9 orthographic camera.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      setState(() {
        _selectionRequest += 1;
      });
    });
  }

  void _selectFloor(String floor) {
    if (!_floors.contains(floor)) return;

    setState(() {
      _selectedFloor = floor;
      _selectionRequest += 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: IgnorePointer(
              ignoring: true,
              child: HomeSplineMap(
                selectedFloor: _selectedFloor,
                selectionRequest: _selectionRequest,
                visibleFloorNames: <String>{_selectedFloor},
              ),
            ),
          ),
        ),
        Positioned(
          left: 4,
          top: 16,
          child: HomeFloorSelector(
            floors: _floors,
            selectedFloor: _selectedFloor,
            onFloorSelected: _selectFloor,
          ),
        ),
      ],
    );
  }
}
