import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:massdrive/core/auth/account_status_notifier.dart';
import 'package:massdrive/core/auth/session_notifier.dart';
import 'package:massdrive/features/account_restricted/presentation/screens/account_restricted_screen.dart';
import 'package:massdrive/core/constants/app_routes.dart';
import 'package:massdrive/core/update/force_update_screen.dart';
import 'package:massdrive/core/update/update_check.dart';
import 'package:massdrive/features/edit_profile/presentation/screens/edit_profile_screen.dart';
import 'package:massdrive/features/home/presentation/screens/home_screen.dart';
import 'package:massdrive/features/incoming_job/presentation/screens/incoming_job_screen.dart';
import 'package:massdrive/features/income/presentation/screens/income_screen.dart';
import 'package:massdrive/features/main/screens/splash_screen.dart';
import 'package:massdrive/features/profile/presentation/screens/profile_screen.dart';
import 'package:massdrive/features/service_type/presentation/screens/service_type_screen.dart';
import 'package:massdrive/features/auth/presentation/screens/login_screen.dart';
import 'package:massdrive/features/auth/presentation/screens/otp_screen.dart';
import 'package:massdrive/features/auth/presentation/screens/register_screen.dart';
import 'package:massdrive/features/setting/presentation/screens/setting_screen.dart';
import 'package:massdrive/features/job_live/presentation/screens/job_live_screen.dart';
import 'package:massdrive/features/income/presentation/screens/held_fares_screen.dart';
import 'package:massdrive/features/income/presentation/screens/payout_history_screen.dart';
import 'package:massdrive/features/payment/presentation/screens/payment_screen.dart';
import 'package:massdrive/features/review/data/customer_review_api.dart';
import 'package:massdrive/features/review/presentation/screens/review_customer_screen.dart';
import 'package:massdrive/features/income/presentation/screens/cash_wallet_screen.dart';
import 'package:massdrive/features/income/presentation/screens/credit_wallet_screen.dart';
import 'package:massdrive/features/food_live/presentation/screens/food_live_screen.dart';
import 'package:massdrive/features/messenger/presentation/screens/messenger_offer_screen.dart';
import 'package:massdrive/features/messenger/presentation/screens/messenger_live_screen.dart';
import 'package:massdrive/features/messenger/presentation/screens/messenger_history_screen.dart';

import 'package:massdrive/features/document_registration/domain/models/registration_status.dart';
import 'package:massdrive/features/document_registration/presentation/screens/registration_checklist_screen.dart';
import 'package:massdrive/features/document_registration/presentation/screens/basic_profile_form_screen.dart';
import 'package:massdrive/features/document_registration/presentation/screens/document_upload_screen.dart';
import 'package:massdrive/features/document_registration/presentation/screens/vehicle_info_form_screen.dart';
import 'package:massdrive/features/document_registration/presentation/screens/bank_account_form_screen.dart';
import 'package:massdrive/features/document_registration/presentation/screens/consent_screen.dart';
import 'package:massdrive/features/fcm_debug/presentation/screens/fcm_debug_screen.dart';
import 'package:massdrive/features/history/presentation/screens/history_screen.dart';
import 'package:massdrive/features/quests/presentation/screens/quests_screen.dart';
import 'package:massdrive/features/profile/presentation/screens/trip_calendar_screen.dart';
import 'package:massdrive/features/income/presentation/screens/topup_history_screen.dart';
import 'package:massdrive/features/income/presentation/screens/transaction_history_screen.dart';
import 'package:massdrive/features/income/presentation/statement_entries.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  /// Context of the root navigator, for app-wide dialogs raised outside any
  /// screen (e.g. "งานถูกยกเลิก").
  static BuildContext? get rootContext => _rootNavigatorKey.currentContext;
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  /// Routes reachable while logged out. Everything else requires a live session;
  /// when there isn't one, [_router]'s redirect sends the driver to login.
  static const Set<String> _publicRoutes = {
    AppRoutes.splashNamedPage,
    AppRoutes.loginNamedPage,
    AppRoutes.registerNamedPage,
    AppRoutes.otpNamedPage,
  };

  /// The only places a deleted/suspended driver may be (plus logged-out flow).
  static const Set<String> _restrictedAllowedRoutes = {
    AppRoutes.accountRestrictedNamedPage,
    AppRoutes.settingNamedPage,
    AppRoutes.splashNamedPage,
    AppRoutes.loginNamedPage,
  };

  /// An offer, a live job or the collect screen: a forced update waits until
  /// the driver navigates off these rather than tearing the job down.
  static const Set<String> _activeJobRoutes = {
    AppRoutes.incomingJobNamedPage,
    '/job-live',
    AppRoutes.foodLiveNamedPage,
    '/messenger-offer',
    '/messenger-live',
    '/payment',
  };

  /// Set by UpdateListener: true while the call screen is up. A forced update
  /// waits for the call to end.
  static bool Function() isInCall = () => false;

  static String get _currentPath {
    final config = _router.routerDelegate.currentConfiguration;
    return config.isEmpty ? '' : config.uri.path;
  }

  /// Nothing the driver is in the middle of: a fine time for the "update
  /// available" dialog.
  static bool get isQuietMoment {
    final path = _currentPath;
    return path.isNotEmpty &&
        path != AppRoutes.splashNamedPage &&
        path != AppRoutes.forceUpdateNamedPage &&
        !_activeJobRoutes.contains(path) &&
        !isInCall();
  }

  /// Where a forced update sends [location], or null to let it through: off
  /// to the update screen unless a call is up or the driver is already in a
  /// job and stays in it.
  static String? _forceUpdateRedirect(String location) {
    if (location == AppRoutes.forceUpdateNamedPage) return null;
    if (isInCall()) return null;
    final from = _currentPath;
    final staysInJob =
        _activeJobRoutes.contains(location) &&
        (from == location || _activeJobRoutes.contains(from));
    return staysInJob ? null : AppRoutes.forceUpdateNamedPage;
  }

  static final GoRouter _router = GoRouter(
    initialLocation: AppRoutes.splashNamedPage,
    debugLogDiagnostics: true,
    navigatorKey: _rootNavigatorKey,
    // Re-run [redirect] whenever the session flips (login, logout, expiry, or a
    // 401 on an authenticated request) so a dead session can't stay on a
    // protected screen — the core fix for "stale session never returns to
    // login".
    // Also re-run it when the account is flagged deleted/suspended.
    // And when the backend starts or stops forcing an update.
    refreshListenable: Listenable.merge([
      SessionNotifier.instance,
      AccountStatusNotifier.instance,
      UpdateCheck.instance,
    ]),
    redirect: (context, state) {
      final loggedIn = SessionNotifier.instance.isAuthenticated;
      final location = state.matchedLocation;

      // This build must update: hold the app on the update screen. It outranks
      // every other rule, logged in or not, since an old build may not work.
      if (UpdateCheck.instance.forced != null) {
        return _forceUpdateRedirect(location);
      }
      if (location == AppRoutes.forceUpdateNamedPage) {
        return AppRoutes.splashNamedPage;
      }

      final atPublicRoute = _publicRoutes.contains(location);
      if (!loggedIn && !atPublicRoute) {
        return AppRoutes.loginNamedPage;
      }

      // Deleted / suspended account: keep the driver on the "contact the
      // company" screen. Settings stays reachable (it only offers logout).
      final restricted = AccountStatusNotifier.instance.isRestricted;
      if (loggedIn &&
          restricted &&
          !_restrictedAllowedRoutes.contains(location)) {
        return AppRoutes.accountRestrictedNamedPage;
      }
      if (!restricted && location == AppRoutes.accountRestrictedNamedPage) {
        return AppRoutes.homeNamedPage;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.forceUpdateNamedPage,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: ForceUpdateScreen()),
      ),
      GoRoute(
        path: AppRoutes.accountRestrictedNamedPage,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: AccountRestrictedScreen()),
      ),
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
        path: AppRoutes.registerNamedPage,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: RegisterScreen()),
      ),
      GoRoute(
        path: AppRoutes.otpNamedPage,
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final phone = extra['phone'] as String? ?? '';
          final refId = extra['refId'] as String? ?? '';
          final isRegistered = extra['isRegistered'] as bool? ?? true;
          return NoTransitionPage(
            child: OtpScreen(
              phoneNumber: phone,
              refId: refId,
              isRegistered: isRegistered,
            ),
          );
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
      // Lists opened from รายได้ / โปรไฟล์ — routes (not bare Navigator pages)
      // so a background kill can bring the driver back to them.
      GoRoute(
        path: AppRoutes.historyNamedPage,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: HistoryScreen()),
      ),
      GoRoute(
        path: AppRoutes.questsNamedPage,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: QuestsScreen()),
      ),
      GoRoute(
        path: AppRoutes.tripCalendarNamedPage,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: TripCalendarScreen()),
      ),
      GoRoute(
        path: AppRoutes.topupHistoryNamedPage,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: TopupHistoryScreen()),
      ),
      GoRoute(
        path: AppRoutes.transactionsNamedPage,
        pageBuilder: (context, state) => const NoTransitionPage(
          child: TransactionHistoryScreen(
            title: 'รายการทั้งหมด',
            scope: StatementScope.jobs,
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.creditHistoryNamedPage,
        pageBuilder: (context, state) => const NoTransitionPage(
          child: TransactionHistoryScreen(
            title: 'ประวัติเครดิต',
            scope: StatementScope.wallet,
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.cashWalletNamedPage,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: CashWalletScreen()),
      ),
      GoRoute(
        path: AppRoutes.payoutHistoryNamedPage,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: PayoutHistoryScreen()),
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
        pageBuilder: (context, state) => NoTransitionPage(
          child: JobLiveScreen(initialStatus: state.extra as String?),
        ),
      ),
      GoRoute(
        path: AppRoutes.foodLiveNamedPage,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: FoodLiveScreen()),
      ),
      GoRoute(
        path: '/messenger-offer',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: MessengerOfferScreen()),
      ),
      GoRoute(
        path: '/messenger-live',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: MessengerLiveScreen()),
      ),
      GoRoute(
        path: '/messenger-history',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: MessengerHistoryScreen()),
      ),
      GoRoute(
        path: '/held-fares',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: HeldFaresScreen()),
      ),
      GoRoute(
        path: '/payment',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return NoTransitionPage(
            child: PaymentScreen(
              amount: (extra?['amount'] as num?)?.toDouble(),
              codAmount: (extra?['codAmount'] as num?)?.toDouble(),
              methodLabel: extra?['method'] as String?,
              payer: extra?['payer'] as String?,
              collectAt: extra?['collectAt'] as String?,
              paymentStatus: extra?['paymentStatus'] as String?,
              title: extra?['title'] as String?,
              orderId: extra?['orderId'] as String?,
              service: extra?['service'] as ReviewService?,
              gateCompletion: extra?['gateCompletion'] as bool? ?? false,
              midTrip: extra?['midTrip'] as bool? ?? false,
            ),
          );
        },
      ),
      GoRoute(
        path: '/review-customer',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return NoTransitionPage(
            child: ReviewCustomerScreen(
              jobId: extra['jobId'] as String? ?? '',
              service: extra['service'] as ReviewService? ?? ReviewService.ride,
              customerName: extra['customerName'] as String? ?? 'ลูกค้า',
              avatarUrl: extra['avatarUrl'] as String?,
              subtitle: extra['subtitle'] as String?,
              previewMode: extra['previewMode'] as bool? ?? false,
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.documentRegistrationChecklistNamedPage,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: RegistrationChecklistScreen()),
      ),
      GoRoute(
        path: AppRoutes.documentRegistrationProfileNamedPage,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: BasicProfileFormScreen()),
      ),
      GoRoute(
        path: AppRoutes.documentRegistrationUploadNamedPage,
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return NoTransitionPage(
            child: DocumentUploadScreen(
              type: extra['type'] as DocumentType? ?? DocumentType.profilePhoto,
              title: extra['title'] as String? ?? 'Upload',
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.documentRegistrationVehicleNamedPage,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: VehicleInfoFormScreen()),
      ),
      GoRoute(
        path: AppRoutes.documentRegistrationBankNamedPage,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: BankAccountFormScreen()),
      ),
      GoRoute(
        path: AppRoutes.documentRegistrationConsentNamedPage,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: ConsentScreen()),
      ),
      GoRoute(
        path: AppRoutes.fcmDebugNamedPage,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: FcmDebugScreen()),
      ),
    ],
    // An unknown location (a stale restored route, or a notification `route`
    // the app doesn't define) used to render HomeScreen via errorBuilder. That
    // only *looked* like home: the router was left in its error state with no
    // matched routes, so every later `context.push` (settings, "ไปที่ลงทะเบียน
    // คนขับ", …) silently did nothing. Navigate to the real /home instead so
    // the stack is valid again.
    onException: (context, state, router) {
      debugPrint('Router: no route for ${state.uri} — going to home');
      router.go(AppRoutes.homeNamedPage);
    },
  );

  static GoRouter get router => _router;

  /// Whether [location] matches a route this app defines.
  static bool isKnownLocation(String location) {
    final uri = Uri.tryParse(location);
    if (uri == null) return false;
    return !_router.configuration.findMatch(uri).isError;
  }
}
