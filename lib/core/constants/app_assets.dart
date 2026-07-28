/// Central paths for static files bundled with CampusGO.
///
/// Keeping paths here prevents screens from repeating string literals. If an
/// asset is renamed later, only this file needs to change.
abstract final class AppAssets {
  static const String loginBackground =
      'assets/features/auth/login_background.png';

  static const String campusGoLocationPin =
      'assets/branding/logos/campusgo_location_pin.png';
}
