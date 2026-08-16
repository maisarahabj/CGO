import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../navigation/models/destination_model.dart';
import '../models/ongoing_class_model.dart';
import 'home_location_fields.dart';

/// Rounded home control panel that expands upward from the bottom of the map.
class HomeNavigationPanel extends StatelessWidget {
  const HomeNavigationPanel({
    required this.isExpanded,
    required this.isRegisteredUser,
    required this.bottomSafeArea,
    required this.nextClasses,
    required this.currentLocationController,
    required this.currentLocationFocusNode,
    required this.destinationController,
    required this.destinationFocusNode,
    required this.isDestinationEditable,
    required this.currentLocationOptionsBuilder,
    required this.destinationOptionsBuilder,
    required this.onCurrentLocationSelected,
    required this.onDestinationSelected,
    required this.onCurrentLocationTextChanged,
    required this.onDestinationTextChanged,
    required this.canStartNavigation,
    required this.isNavigationLoading,
    required this.onCurrentLocationPressed,
    required this.onQrPressed,
    required this.onDestinationPressed,
    required this.onStartNavigationPressed,
    required this.onDestinationSwipeUp,
    required this.onDestinationSwipeDown,
    required this.onBackgroundPressed,
    required this.onNavigatePressed,
    required this.onViewAllPressed,
    this.ongoingClass,
    super.key,
  });

  final bool isExpanded;
  final bool isRegisteredUser;
  final double bottomSafeArea;
  final OngoingClassModel? ongoingClass;
  final List<OngoingClassModel> nextClasses;
  final TextEditingController currentLocationController;
  final FocusNode currentLocationFocusNode;
  final TextEditingController destinationController;
  final FocusNode destinationFocusNode;
  final bool isDestinationEditable;
  final AutocompleteOptionsBuilder<DestinationModel>
      currentLocationOptionsBuilder;
  final AutocompleteOptionsBuilder<DestinationModel> destinationOptionsBuilder;
  final AutocompleteOnSelected<DestinationModel> onCurrentLocationSelected;
  final AutocompleteOnSelected<DestinationModel> onDestinationSelected;
  final ValueChanged<String> onCurrentLocationTextChanged;
  final ValueChanged<String> onDestinationTextChanged;
  final bool canStartNavigation;
  final bool isNavigationLoading;
  final VoidCallback onCurrentLocationPressed;
  final VoidCallback onQrPressed;
  final VoidCallback onDestinationPressed;
  final VoidCallback onStartNavigationPressed;
  final VoidCallback onDestinationSwipeUp;
  final VoidCallback onDestinationSwipeDown;
  final VoidCallback onBackgroundPressed;
  final ValueChanged<OngoingClassModel> onNavigatePressed;
  final VoidCallback onViewAllPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onBackgroundPressed,
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          // This is the white background only.
          Positioned(
            top: 8,
            left: 0,
            right: 0,
            bottom: 0,
            child: Material(
              color: Colors.white,
              elevation: 8,
              shadowColor: const Color(0x30000000),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(57),
              ),
              clipBehavior: Clip.antiAlias,
            ),
          ),

          // These are the contents above the white background.
          // Their position does not change.
          Column(
            children: [
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: HomeLocationFields(
                  currentLocationController: currentLocationController,
                  currentLocationFocusNode: currentLocationFocusNode,
                  destinationController: destinationController,
                  destinationFocusNode: destinationFocusNode,
                  isDestinationEditable: isDestinationEditable,
                  currentLocationOptionsBuilder: currentLocationOptionsBuilder,
                  destinationOptionsBuilder: destinationOptionsBuilder,
                  onCurrentLocationSelected: onCurrentLocationSelected,
                  onDestinationSelected: onDestinationSelected,
                  onCurrentLocationTextChanged: onCurrentLocationTextChanged,
                  onDestinationTextChanged: onDestinationTextChanged,
                  canStartNavigation: canStartNavigation,
                  isNavigationLoading: isNavigationLoading,
                  onCurrentLocationPressed: onCurrentLocationPressed,
                  onQrPressed: onQrPressed,
                  onDestinationPressed: onDestinationPressed,
                  onStartNavigationPressed: onStartNavigationPressed,
                  onDestinationSwipeUp: onDestinationSwipeUp,
                  onDestinationSwipeDown: onDestinationSwipeDown,
                ),
              ),
              if (isExpanded && isRegisteredUser) ...[
                const SizedBox(height: 12),
                Expanded(
                  child: _ScheduleContent(
                    ongoingClass: ongoingClass,
                    nextClasses: nextClasses,
                    bottomSafeArea: bottomSafeArea,
                    onNavigatePressed: onNavigatePressed,
                    onViewAllPressed: onViewAllPressed,
                  ),
                ),
              ] else
                SizedBox(height: bottomSafeArea + 10),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScheduleContent extends StatelessWidget {
  const _ScheduleContent({
    required this.ongoingClass,
    required this.nextClasses,
    required this.bottomSafeArea,
    required this.onNavigatePressed,
    required this.onViewAllPressed,
  });

  final OngoingClassModel? ongoingClass;
  final List<OngoingClassModel> nextClasses;
  final double bottomSafeArea;
  final ValueChanged<OngoingClassModel> onNavigatePressed;
  final VoidCallback onViewAllPressed;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottomSafeArea + 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (ongoingClass != null) ...[
            const _SectionTitle(title: 'Ongoing Class'),
            const SizedBox(height: 8),
            _ScheduleClassCard(
              scheduledClass: ongoingClass!,
              isOngoing: true,
              onNavigatePressed: () => onNavigatePressed(ongoingClass!),
            ),
            const SizedBox(height: 14),
          ],
          Row(
            children: [
              const Expanded(child: _SectionTitle(title: 'Next Classes')),
              TextButton(
                onPressed: onViewAllPressed,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF61727D),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: const Size(56, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'View All',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (nextClasses.isEmpty)
            const _EmptyScheduleCard()
          else
            for (final scheduledClass in nextClasses)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ScheduleClassCard(
                  scheduledClass: scheduledClass,
                  onNavigatePressed: () => onNavigatePressed(scheduledClass),
                ),
              ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Roboto',
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Color(0xFF234B66),
        height: 1,
      ),
    );
  }
}

class _ScheduleClassCard extends StatelessWidget {
  const _ScheduleClassCard({
    required this.scheduledClass,
    required this.onNavigatePressed,
    this.isOngoing = false,
  });

  final OngoingClassModel scheduledClass;
  final VoidCallback onNavigatePressed;
  final bool isOngoing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE3E7EA)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x16000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 68,
            height: 68,
            child: Image.asset(
              AppAssets.classroomIllustration,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        scheduledClass.roomName.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2A77B4),
                          height: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      scheduledClass.timeRange,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF8B94AA),
                        height: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        scheduledClass.subjectName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF61727D),
                          height: 1,
                        ),
                      ),
                    ),
                    if (isOngoing) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBBB00),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'ON-GOING',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 7,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${scheduledClass.floorLabel}, '
                  '${scheduledClass.buildingLabel}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF9AA2B4),
                    height: 1,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 28,
                  child: OutlinedButton(
                    onPressed: onNavigatePressed,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2A77B4),
                      side: const BorderSide(color: Color(0xFF2A77B4)),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      minimumSize: const Size(118, 28),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Navigate Now',
                          style: TextStyle(
                            fontFamily: 'Raleway',
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(width: 5),
                        Icon(Icons.chevron_right, size: 14),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyScheduleCard extends StatelessWidget {
  const _EmptyScheduleCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8F9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE3E7EA)),
      ),
      child: const Text(
        'No more classes are scheduled for today.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Color(0xFF61727D),
        ),
      ),
    );
  }
}
