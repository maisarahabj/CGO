import 'dart:math' as math;
import 'dart:ui' show FontVariation;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';
import '../../navigation/models/destination_model.dart';
import '../../navigation/models/route_result.dart';

/// Bottom card shown while a route is active.
///
/// It intentionally replaces the normal location-input panel only after
/// Dijkstra has produced a RouteResult. This keeps destination selection and
/// route display as separate UI states and lets the ETA use the real route
/// cost that was calculated for the currently visible route.
class HomeRouteSummaryPanel extends StatelessWidget {
  const HomeRouteSummaryPanel({
    required this.destination,
    required this.routeResult,
    required this.bottomSafeArea,
    required this.onClosePressed,
    super.key,
  });

  final DestinationModel destination;
  final RouteResult routeResult;
  final double bottomSafeArea;
  final VoidCallback onClosePressed;

  /// CampusGO prototype ETA conversion:
  /// 100 distance-weight units = 1 metre, and 1 metre = 1 second.
  ///
  /// Therefore:
  /// estimated seconds = route weight / 100.
  static const double _weightUnitsPerMetre = 100.0;
  static const double _secondsPerMetre = 1.0;

  static const Color _campusBlue = Color(0xFF2A77B4);
  static const Color _metaColor = Color(0xAB61727D); // 67% opacity.

  String get _estimatedTimeLabel {
    final estimatedMetres =
        math.max(0, routeResult.totalCost) / _weightUnitsPerMetre;
    final estimatedSeconds = estimatedMetres * _secondsPerMetre;

    if (estimatedSeconds < 60) {
      final seconds = math.max(1, estimatedSeconds.ceil());
      return '$seconds sec away';
    }

    final minutes = math.max(1, (estimatedSeconds / 60).ceil());
    return '$minutes min away';
  }

  String get _floorLabel {
    final rawFloor = destination.floorId?.trim();

    if (rawFloor == null || rawFloor.isEmpty) {
      return 'Menara BAC';
    }

    final normalized = rawFloor.toUpperCase();

    if (normalized == 'G' || normalized.contains('GROUND')) {
      return 'Ground Floor, Menara BAC';
    }

    final levelMatch = RegExp(r'\d+').firstMatch(normalized);
    final level = levelMatch?.group(0);

    if (level != null) {
      return 'Level $level, Menara BAC';
    }

    return '$rawFloor, Menara BAC';
  }

  String get _destinationIllustration {
    final node = destination.node;
    final nodeType = node.nodeType?.trim().toLowerCase() ?? '';
    final searchableDescription = [
      node.nodeType,
      node.label,
      node.description,
      node.tags,
    ].whereType<String>().join(' ').toLowerCase();

    // Surau and washroom need semantic checks as well as node_type because the
    // CURRENT Supabase data contains some of them under the broader `facility`
    // type.
    if (searchableDescription.contains('surau') ||
        searchableDescription.contains('prayer') ||
        searchableDescription.contains('pray')) {
      return AppAssets.destinationSurau;
    }

    if (nodeType == 'washroom' ||
        searchableDescription.contains('washroom') ||
        searchableDescription.contains('toilet') ||
        searchableDescription.contains('restroom')) {
      return AppAssets.destinationWashroom;
    }

    if (nodeType == 'classroom') {
      return AppAssets.destinationClassroom;
    }

    if (nodeType == 'office') {
      return AppAssets.destinationOffice;
    }

    // Facilities, auditoriums, meeting/discussion rooms, and any uncommon
    // destination types use the general facilities illustration as fallback.
    return AppAssets.destinationFacilities;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
          boxShadow: [
            BoxShadow(
              color: Color(0x26000000),
              blurRadius: 14,
              offset: Offset(0, -2),
            ),
          ],
        ),
        padding: EdgeInsets.fromLTRB(18, 14, 14, bottomSafeArea + 10),
        child: Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 78,
                  height: 78,
                  child: Image.asset(
                    _destinationIllustration,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    // Reserve room for the close button so long room names do
                    // not run underneath it.
                    padding: const EdgeInsets.only(right: 38),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          destination.name.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 26,
                            fontWeight: FontWeight.w500,
                            fontVariations: [
                              FontVariation('wdth', 75),
                              FontVariation('wght', 500),
                            ],
                            height: 1.0,
                            color: _campusBlue,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Row(
                          children: [
                            SvgPicture.asset(
                              AppAssets.clock,
                              width: 14,
                              height: 14,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _estimatedTimeLabel,
                              style: const TextStyle(
                                fontFamily: 'Raleway',
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: _metaColor,
                                height: 1,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(
                              Icons.near_me_outlined,
                              size: 16,
                              color: _metaColor,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _floorLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Raleway',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: _metaColor,
                                  height: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              top: 0,
              right: 0,
              child: Semantics(
                button: true,
                label: 'Close active route',
                child: InkResponse(
                  onTap: onClosePressed,
                  radius: 24,
                  child: SizedBox(
                    width: 38,
                    height: 38,
                    child: Center(
                      child: SvgPicture.asset(
                        AppAssets.closeBorderButton,
                        width: 29,
                        height: 26,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
