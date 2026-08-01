/// The three access levels understood by the CampusGO interface.
///
/// `guest` means there is no Supabase Auth session. The `user` and `admin`
/// values should be loaded from the authenticated user's profile.
enum UserRole { guest, user, admin }
