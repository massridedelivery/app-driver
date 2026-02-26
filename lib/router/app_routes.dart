import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:massdrive/core/constants/app_routes.dart';
import 'package:massdrive/features/edit_profile/presentation/screens/edit_profile_screen.dart';
import 'package:massdrive/features/home/presentation/screens/home_screen.dart';
import 'package:massdrive/features/incoming_job/presentation/screens/incoming_job_screen.dart';
import 'package:massdrive/features/income/presentation/screens/income_screen.dart';
import 'package:massdrive/features/main/screens/splash_screen.dart';
import 'package:massdrive/features/profile/presentation/screens/profile_screen.dart';
import 'package:massdrive/features/service_type/presentation/screens/service_type_screen.dart';
import 'package:massdrive/features/auth/presentation/screens/login_screen.dart';
import 'package:massdrive/features/auth/presentation/screens/email_login_screen.dart';
import 'package:massdrive/features/auth/presentation/screens/otp_screen.dart';
import 'package:massdrive/features/auth/presentation/screens/register_screen.dart';
import 'package:massdrive/features/setting/presentation/screens/setting_screen.dart';
import 'package:massdrive/features/job_live/presentation/screens/job_live_screen.dart';
import 'package:massdrive/features/payment/presentation/screens/payment_screen.dart';
import 'package:massdrive/features/income/presentation/screens/cash_wallet_screen.dart';
import 'package:massdrive/features/income/presentation/screens/credit_wallet_screen.dart';

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
        path: AppRoutes.loginNamedPage,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: LoginScreen()),
      ),
      GoRoute(
        path: AppRoutes.emailLoginNamedPage,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: EmailLoginScreen()),
      ),
      GoRoute(
        path: AppRoutes.registerNamedPage,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: RegisterScreen()),
      ),
      GoRoute(
        path: AppRoutes.otpNamedPage,
        pageBuilder: (context, state) {
          final phone = state.extra as String? ?? '';
          return NoTransitionPage(child: OtpScreen(phoneNumber: phone));
        },
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
        path: AppRoutes.cashWalletNamedPage,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: CashWalletScreen()),
      ),
      GoRoute(
        path: AppRoutes.creditWalletNamedPage,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: CreditWalletScreen()),
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
      GoRoute(
        path: AppRoutes.incomingJobNamedPage,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: IncomingJobScreen()),
      ),
      GoRoute(
        path: '/job-live',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: JobLiveScreen()),
      ),
      GoRoute(
        path: '/payment',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: PaymentScreen()),
      ),
    ],
    errorBuilder: (context, state) => const HomeScreen(),
  );

  static GoRouter get router => _router;
}
