import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:massdrive/features/home/presentation/screens/home_screen.dart';

class AppRoutes {
  static const root = '/';
  static const splashNamedPage = '/splash';
  static const loginNamedPage = '/login';
  static const otpNamedPage = '/otp_screen';
  static const homeNamedPage = '/home';
  static const homeDetailsNamedPage = 'details';
  static const incomeNamedPage = '/home';
  static const incomeDetailsNamedPage = 'details';
  static const profileNamedPage = '/profile';
  static const profileDetailsNamedPage = 'details';
  static const editProfileNamedPage = '/editProfile';
  static const editProfileDetailsNamedPage = 'details';
  static const serviceTypeNamedPage = '/service';
  static const serviceTypeDetailsNamedPage = 'details';
  static const historyNamedPage = '/history';
  static const historyDetailsNamedPage = 'details';
  static const historyDetailNamedPage = '/history_detail';
  static const historyDetailDetailsNamedPage = 'details';
  static const settingNamedPage = '/setting';
  static const settingDetailsNamedPage = 'details';
  static const incomingJobNamedPage = '/incoming-job';

  static Widget errorWidget(BuildContext context, GoRouterState state) =>
      const HomeScreen();

  // =========================
  // Root / Standalone
  // =========================
  static const splashPath = '/splash';
  static const onboardingPath = '/onboarding';
  static const loginPath = '/login';

  // =========================
  // Shell
  // =========================
  static const shellPath = '/app';

  // =========================
  // Shell tabs (RELATIVE)
  // =========================
  static const homePath = 'home';
  static const incomePath = 'incomePath';
  static const profilePath = 'profile';

  // =========================
  // Others (push from anywhere)
  // =========================
  static const settingsPath = '/settings';
  static const webViewPath = '/webview';
  static const checkoutPath = '/checkout';
  static const talkerPath = '/debug_talker';

  // =========================
  // Names
  // =========================
  static const splashName = 'splash';
  static const onboardingName = 'onboarding';
  static const loginName = 'login';

  static const shellName = 'shell';

  static const homeName = 'home';
  static const incomeName = 'income';
  static const myCartName = 'my_cart';
  static const profileName = 'profile';

  static const settingsName = 'settings';
  static const webViewName = 'webview';
  static const checkoutName = 'checkout';
  static const talkerName = 'debug_talker';
}
