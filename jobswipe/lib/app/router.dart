import 'package:go_router/go_router.dart';
import 'package:jobswipe/features/auth/presentation/login_page.dart';
import 'package:jobswipe/features/company/presentation/company_dashboard_page.dart';
import 'package:jobswipe/features/feed/presentation/feed_page.dart';
import 'package:jobswipe/features/splash/presentation/splash_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashPage()),
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    GoRoute(path: '/feed', builder: (context, state) => const FeedPage()),
    GoRoute(
      path: '/company-dashboard',
      builder: (context, state) => const CompanyDashboardPage(),
    ),
  ],
);
