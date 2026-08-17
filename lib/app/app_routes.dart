/// Named routes used throughout the CampusGO application.
abstract final class AppRoutes {
  static const String home = '/';
  static const String login = '/login';
  static const String guestHome = '/guest';
  static const String userHome = '/home';
  static const String adminDashboard = '/admin';

  static const String notifications = '/notifications';
  static const String timetable = '/timetable';
  static const String bookings = '/bookings';

  static const String settings = '/settings';
  static const String support = '/support';
  static const String issueReport = '/support/issue-report';
  static const String editProfile = '/profile/edit';

  static const String qrScanner = '/navigation/qr-scanner';

  static const String adminNotifications = '/admin/notifications';
  static const String adminBookingRequests = '/admin/booking-requests';
  static const String adminRoomAvailability = '/admin/rooms-availability';
  static const String adminMapManagement = '/admin/map-management';
  static const String adminRouteManagement = '/admin/route-management';
  static const String adminIssueReports = '/admin/issue-reports';
  static const String adminQrCheckpoints = '/admin/qr-checkpoints';
  static const String adminUserProfiles = '/admin/user-profiles';

  static const String privacyLegalHelp = '/privacy-legal-help';

  // Settings / Legal.
  static const String aboutCampusGo = '/settings/about';
  static const String termsOfUse = '/settings/terms';
  static const String privacyPolicy = '/settings/privacy';
}
