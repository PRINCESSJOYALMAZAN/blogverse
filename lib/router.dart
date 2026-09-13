import 'package:go_router/go_router.dart';

import 'providers/auth_provider.dart';
import 'screens/feed_screen.dart';
import 'screens/login_screen.dart';
import 'screens/post_detail_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/write_screen.dart';

GoRouter createRouter(AuthStateProvider auth) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: auth,
    redirect: (context, state) {
      final privateRoute = state.matchedLocation.startsWith('/new') ||
          state.matchedLocation.startsWith('/edit') ||
          state.matchedLocation.startsWith('/profile');
      if (privateRoute && !auth.isLoggedIn) return '/login';
      if ((state.matchedLocation == '/login' ||
              state.matchedLocation == '/register') &&
          auth.isLoggedIn) {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const FeedScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginScreen(
          initialEmail: state.uri.queryParameters['email'],
        ),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => SignUpScreen(
          initialEmail: state.uri.queryParameters['email'],
        ),
      ),
      GoRoute(
        path: '/new',
        builder: (context, state) => const WriteScreen(),
      ),
      GoRoute(
        path: '/posts/:id',
        builder: (context, state) => PostDetailScreen(
          postId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/edit/:id',
        builder: (context, state) => WriteScreen(
          postId: state.pathParameters['id'],
        ),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
}
