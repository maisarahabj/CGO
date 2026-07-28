// TODO: Implement authentication state and coordinate AuthService.
//
// This controller should answer two different questions:
// 1. Is there a current Supabase Auth session?
// 2. If there is a session, is the profile role "user" or "admin"?
//
// No session          -> UserRole.guest
// Session + user role -> UserRole.user
// Session + admin     -> UserRole.admin
//
// Keep role loading here instead of placing Supabase queries inside screens.
