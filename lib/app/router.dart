import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/login_screen.dart';
import '../features/expenses/presentation/expenses_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/juntadas/presentation/juntadas_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/prode/presentation/prode_screen.dart';
import '../features/stats/presentation/stats_screen.dart';
import '../shared/providers/user_provider.dart';

class AppRoutes {
  AppRoutes._();
  static const login = '/login';
  static const home = '/';
  static const profile = '/profile';
  static const expenses = '/expenses';
  static const juntadas = '/juntadas';
  static const stats = '/stats';
  static const prode = '/prode';
}

final routerProvider = Provider<GoRouter>((ref) {
  final loggedIn = ref.watch(isLoggedInProvider);

  return GoRouter(
    initialLocation: AppRoutes.home,
    redirect: (context, state) {
      final atLogin = state.matchedLocation == AppRoutes.login;
      if (!loggedIn && !atLogin) return AppRoutes.login;
      if (loggedIn && atLogin) return AppRoutes.home;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (_, _s) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (_, _s) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (_, _s) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.expenses,
        builder: (_, _s) => const ExpensesScreen(),
      ),
      GoRoute(
        path: AppRoutes.juntadas,
        builder: (_, _s) => const JuntadasScreen(),
      ),
      GoRoute(
        path: AppRoutes.stats,
        builder: (_, _s) => const StatsScreen(),
      ),
      GoRoute(
        path: AppRoutes.prode,
        builder: (_, _s) => const ProdeScreen(),
      ),
    ],
  );
});
