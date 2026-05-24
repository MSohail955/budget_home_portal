import 'dart:html' as html;

import 'package:go_router/go_router.dart';

import '../../core/providers/auth_provider.dart';
import '../../features/auth/presentation/auth_screen.dart';
import '../../features/dashboard/presentation/main_shell_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';

class AppRouter {
  static GoRouter createRouter(AuthProvider authProvider) {
    final hasSeenOnboarding =
        html.window.localStorage['budget_home_onboarding_seen'] == 'true';

    return GoRouter(
      initialLocation: hasSeenOnboarding ? '/app' : '/onboarding',
      refreshListenable: authProvider,
      redirect: (context, state) {
        final currentLocation = state.matchedLocation;

        final isAuthRoute =
            currentLocation == '/login' || currentLocation == '/auth';

        final isOnboardingRoute = currentLocation == '/onboarding';

        final isPublicRoute = isAuthRoute || isOnboardingRoute;

        if (authProvider.isLoading) {
          return null;
        }

        if (!authProvider.isLoggedIn && !isPublicRoute) {
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
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/app',
          builder: (context, state) => const MainShellScreen(),
        ),
      ],
    );
  }
}
