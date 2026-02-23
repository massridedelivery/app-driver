import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:massdrive/core/constants/app_routes.dart';
import 'package:massdrive/features/edit_profile/presentation/screens/edit_profile_screen.dart';
import 'package:massdrive/features/home/presentation/screens/home_screen.dart';
import 'package:massdrive/features/income/presentation/screens/income_screen.dart';
import 'package:massdrive/features/main/screens/splash_screen.dart';
import 'package:massdrive/features/profile/presentation/screens/profile_screen.dart';
import 'package:massdrive/features/service_type/presentation/screens/service_type_screen.dart';
import 'package:massdrive/features/setting/presentation/screens/setting_screen.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter _router = GoRouter(
    initialLocation: AppRoutes.splashNamedPage,
    debugLogDiagnostics: true,
    navigatorKey: _rootNavigatorKey,
    routes: [
      GoRoute(
        path: AppRoutes.splashNamedPage,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: SplashScreen()),
      ),
      GoRoute(
        path: AppRoutes.homeNamedPage,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: HomeScreen()),
      ),
      GoRoute(
        path: AppRoutes.incomeNamedPage,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: IncomeScreen()),
      ),
      GoRoute(
        path: AppRoutes.profileNamedPage,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: ProfileScreen()),
      ),
      GoRoute(
        path: AppRoutes.editProfileNamedPage,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: EditProfileScreen()),
      ),
      GoRoute(
        path: AppRoutes.serviceTypeNamedPage,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: ServiceTypeScreen()),
      ),
      GoRoute(
        path: AppRoutes.settingNamedPage,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: SettingScreen()),
      ),
    ],
    errorBuilder: (context, state) => const HomeScreen(),
  );

  static GoRouter get router => _router;
}
