import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jobswipe/core/enums/user_role.dart';
import 'package:jobswipe/features/admin/presentation/admin_dashboard_page.dart';
import 'package:jobswipe/features/auth/presentation/login_page.dart';
import 'package:jobswipe/features/company/presentation/company_dashboard_page.dart';
import 'package:jobswipe/features/home/presentation/main_navigation_page.dart';
import 'package:jobswipe/features/splash/presentation/splash_page.dart';
import 'package:jobswipe/shared/providers/auth_provider.dart';
import 'package:jobswipe/features/auth/presentation/register_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final user = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final location = state.matchedLocation;

      final isAtSplash = location == '/';
      final isAtLogin = location == '/login';
      final isAtRegister = location == '/register';

      if (isAtSplash) {
        return '/login';
      }

      if (!user.isLoggedIn) {
        return (isAtLogin || isAtRegister) ? null : '/login';
      }

      if (isAtLogin || isAtRegister) {
        switch (user.role) {
          case UserRole.candidate:
            return '/feed';
          case UserRole.company:
            return '/company';
          case UserRole.admin:
            return '/admin';
        }
      }

      if (location == '/admin' && user.role != UserRole.admin) {
        switch (user.role) {
          case UserRole.company:
            return '/company';
          case UserRole.candidate:
            return '/feed';
          case UserRole.admin:
            return null;
        }
      }

      if (location == '/company' && user.role != UserRole.company) {
        switch (user.role) {
          case UserRole.admin:
            return '/admin';
          case UserRole.candidate:
            return '/feed';
          case UserRole.company:
            return null;
        }
      }

      if (location == '/feed' && user.role != UserRole.candidate) {
        switch (user.role) {
          case UserRole.admin:
            return '/admin';
          case UserRole.company:
            return '/company';
          case UserRole.candidate:
            return null;
        }
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashPage()),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
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
