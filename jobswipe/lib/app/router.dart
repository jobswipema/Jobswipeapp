import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jobswipe/core/enums/user_role.dart';
import 'package:jobswipe/features/admin/presentation/admin_dashboard_page.dart';
import 'package:jobswipe/features/auth/presentation/login_page.dart';
import 'package:jobswipe/features/company/presentation/company_dashboard_page.dart';
import 'package:jobswipe/features/home/presentation/main_navigation_page.dart';
import 'package:jobswipe/features/splash/presentation/splash_page.dart';
import 'package:jobswipe/shared/providers/auth_provider.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final user = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isAtSplash = state.matchedLocation == '/';
      final isAtLogin = state.matchedLocation == '/login';

      if (isAtSplash) {
        return '/login';
      }

      if (!user.isLoggedIn) {
        return isAtLogin ? null : '/login';
      }

      if (isAtLogin) {
        switch (user.role) {
          case UserRole.candidate:
            return '/feed';
          case UserRole.company:
            return '/company';
          case UserRole.admin:
            return '/admin';
        }
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashPage()),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/feed',
        builder: (context, state) => const MainNavigationPage(),
      ),
      GoRoute(
        path: '/company',
        builder: (context, state) => const CompanyDashboardPage(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardPage(),
      ),
    ],
  );
});
