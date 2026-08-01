import 'ongoing_class_model.dart';

/// Classes that are relevant to the registered user's home screen today.
class HomeScheduleSnapshot {
  const HomeScheduleSnapshot({this.ongoingClass, this.nextClasses = const []});

  final OngoingClassModel? ongoingClass;
  final List<OngoingClassModel> nextClasses;
}
