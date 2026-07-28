// TODO: Route users according to AuthController's current state.
//
// Loading role -> show AppLoadingIndicator
// Guest        -> GuestHomeScreen
// User         -> UserHomeScreen
// Admin        -> AdminDashboardScreen
//
// AuthGate selects the first screen. AppRouter must still protect later route
// changes, and Supabase RLS must protect the actual database operations.
