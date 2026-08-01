import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';
import '../models/ongoing_class_model.dart';

class OngoingClassCard extends StatelessWidget {
  const OngoingClassCard({
    required this.ongoingClass,
    required this.onNavigatePressed,
    required this.onDismissed,
    super.key,
  });

  final OngoingClassModel ongoingClass;
  final VoidCallback onNavigatePressed;
  final VoidCallback onDismissed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 7,
      shadowColor: const Color(0x40000000),
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 114,
        child: Stack(
          children: [
            Positioned(
              left: 12,
              top: 10,
              bottom: 10,
              width: 74,
              child: Image.asset(
                AppAssets.classroomIllustration,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              left: 92,
              right: 12,
              top: 7,
              bottom: 7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 30),
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            ongoingClass.roomName.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2A77B4),
                              height: 1.05,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Color(0xFF8B94AA),
                        ),
                        const SizedBox(width: 7),
                        Flexible(
                          child: Text(
                            ongoingClass.timeRange,
                            maxLines: 1,
                            overflow: TextOverflow.fade,
                            softWrap: false,
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF8B94AA),
                              height: 1.1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          ongoingClass.subjectName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF61727D),
                            height: 1.05,
                          ),
                        ),
                      ),
                      const SizedBox(width: 7),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBBB00),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'ON-GOING',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 6.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule,
                        size: 11,
                        color: Color(0xFF9AA2B4),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${ongoingClass.estimatedWalkMinutes} min away',
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 9.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF9AA2B4),
                          height: 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.location_on_outlined,
                        size: 11,
                        color: Color(0xFF9AA2B4),
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          '${ongoingClass.floorLabel}, ${ongoingClass.buildingLabel}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 9.5,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF9AA2B4),
                            height: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 23,
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      clipBehavior: Clip.antiAlias,
                      child: Ink(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF4D0AA8), Color(0xFFFE6500)],
                          ),
                        ),
                        child: InkWell(
                          onTap: onNavigatePressed,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Navigate Now',
                                style: TextStyle(
                                  fontFamily: 'Raleway',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  height: 1,
                                ),
                              ),
                              SizedBox(width: 7),
                              Icon(
                                Icons.chevron_right,
                                size: 15,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 8,
              right: 10,
              child: Semantics(
                button: true,
                label: 'Dismiss ongoing class reminder',
                child: InkWell(
                  onTap: onDismissed,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: SvgPicture.asset(
                      AppAssets.closeBorderButton,
                      width: 24,
                      height: 21,
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
