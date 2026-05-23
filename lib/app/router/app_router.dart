import 'package:go_router/go_router.dart';

import '../../core/providers/auth_provider.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/dashboard/presentation/main_shell_screen.dart';

class AppRouter {
  static GoRouter createRouter(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: '/app',
      refreshListenable: authProvider,
      redirect: (context, state) {
        final isAuthRoute = state.matchedLocation == '/login' ||
            state.matchedLocation == '/register' ||
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
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/auth',
          redirect: (context, state) => '/login',
        ),
        GoRoute(
          path: '/app',
          builder: (context, state) => const MainShellScreen(),
        ),
      ],
    );
  }
}