import 'package:go_router/go_router.dart';

import '../../core/providers/auth_provider.dart';
import '../../features/auth/presentation/auth_screen.dart';
import '../../features/dashboard/presentation/main_shell_screen.dart';

class AppRouter {
  static GoRouter createRouter(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: '/app',
      refreshListenable: authProvider,
      redirect: (context, state) {
        final isAuthRoute = state.matchedLocation == '/login' ||
            state.matchedLocation == '/auth';

        if (authProvider.isLoading) {
          return null;
        }

        if (!authProvider.isLoggedIn && !isAuthRoute) {
          return '/login';
        }

        if (authProvider.isLoggedIn && isAuthRoute) {
          return '/app';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/',
          redirect: (context, state) => '/app',
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const AuthScreen(),
        ),
        GoRoute(
          path: '/auth',
          builder: (context, state) => const AuthScreen(),
        ),
        GoRoute(
          path: '/app',
          builder: (context, state) => const MainShellScreen(),
        ),
      ],
    );
  }
}