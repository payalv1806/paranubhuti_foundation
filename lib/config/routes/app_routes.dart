// // if user is logged pages viewed 

// // Example of how your config/routes/app_routes.dart should handle the logic
// final router = GoRouter(
//   redirect: (context, state) {
//     final bool isLoggedIn = authProvider.isLoggedIn;
//     final String targetLocation = state.matchedLocation;

//     // List of pages that require an account
//     final protectedRoutes = ['/chat', '/profile/edit', '/volunteer/host', '/history'];

//     if (protectedRoutes.contains(targetLocation) && !isLoggedIn) {
//       // Redirect them to login, but save where they wanted to go!
//       return '/login?redirectTo=$targetLocation';
//     }
//     return null; // Allow access
//   },
//   routes: [ /* your routes here */ ],
// );