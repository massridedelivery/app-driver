import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:massdrive/core/auth/session_notifier.dart';
import 'package:massdrive/core/constants/app_routes.dart';
import 'package:massdrive/features/document_registration/presentation/screens/bank_account_form_screen.dart';
import 'package:massdrive/features/document_registration/presentation/screens/basic_profile_form_screen.dart';
import 'package:massdrive/features/document_registration/presentation/screens/consent_screen.dart';
import 'package:massdrive/features/document_registration/presentation/screens/registration_checklist_screen.dart';
import 'package:massdrive/features/document_registration/presentation/screens/vehicle_info_form_screen.dart';
import 'package:massdrive/features/edit_profile/presentation/screens/edit_profile_screen.dart';
import 'package:massdrive/features/fcm_debug/presentation/screens/fcm_debug_screen.dart';
import 'package:massdrive/features/home/presentation/screens/home_screen.dart';
import 'package:massdrive/features/income/presentation/screens/cash_wallet_screen.dart';
import 'package:massdrive/features/income/presentation/screens/credit_wallet_screen.dart';
import 'package:massdrive/features/income/presentation/screens/income_screen.dart';
import 'package:massdrive/features/messenger/presentation/screens/messenger_history_screen.dart';
import 'package:massdrive/features/profile/presentation/screens/profile_screen.dart';
import 'package:massdrive/features/service_type/presentation/screens/service_type_screen.dart';
import 'package:massdrive/features/setting/presentation/screens/setting_screen.dart';
import 'package:massdrive/router/app_routes.dart';

/// Yields the link the app was launched from, if any.
typedef InitialLink = Future<Uri?> Function();

/// Yields every link delivered while the app is already running.
typedef LinkStream = Stream<Uri> Function();

/// Sends the driver to a route.
typedef Navigate = void Function(String route);

/// Screens a deep link may open.
///
/// Deliberately narrower than the router: a link is an *arbitrary* input, so
/// this only lists screens that render correctly when opened cold, with no
/// in-memory state behind them.
///
/// Left out on purpose:
/// - auth screens (`/login`, `/otp_screen`, …) — reached by the router's own
///   redirect, and `/otp_screen` needs `extra` a URI cannot carry;
/// - the live/offer screens (`/incoming-job`, `/job-live`, `/food-live`,
///   `/messenger-offer`, `/messenger-live`) and `/payment` — their state is the
///   current job, held only in memory, so landing there from a link shows a
///   spinner that never resolves. Same reasoning as `_nonRestorable` in
///   [RouteRestorationService]; home plus the active-job probe recovers a real
///   job properly.
///
/// Note this is *not* the push-notification allowlist. A push naming
/// `/incoming-job` is legitimate — the backend just assigned that job — so
/// PushNotificationService accepts routes this rejects.
///
/// Also the screens themselves, because a link opens them on the root
/// navigator rather than through go_router — see [_goTo]. Same widgets the
/// router builds for these paths; keep the two in step.
///
/// `/document-registration/upload-document` is absent although the router
/// serves it: it needs a `DocumentType` passed as `extra`, which a URI cannot
/// carry, so a link could only ever open it on the wrong document.
final Map<String, WidgetBuilder> deepLinkScreens = {
  AppRoutes.homeNamedPage: (_) => const HomeScreen(),
  AppRoutes.incomeNamedPage: (_) => const IncomeScreen(),
  AppRoutes.cashWalletNamedPage: (_) => const CashWalletScreen(),
  AppRoutes.creditWalletNamedPage: (_) => const CreditWalletScreen(),
  AppRoutes.profileNamedPage: (_) => const ProfileScreen(),
  AppRoutes.editProfileNamedPage: (_) => const EditProfileScreen(),
  AppRoutes.serviceTypeNamedPage: (_) => const ServiceTypeScreen(),
  AppRoutes.settingNamedPage: (_) => const SettingScreen(),
  '/messenger-history': (_) => const MessengerHistoryScreen(),
  AppRoutes.documentRegistrationChecklistNamedPage: (_) =>
      const RegistrationChecklistScreen(),
  AppRoutes.documentRegistrationProfileNamedPage: (_) =>
      const BasicProfileFormScreen(),
  AppRoutes.documentRegistrationVehicleNamedPage: (_) =>
      const VehicleInfoFormScreen(),
  AppRoutes.documentRegistrationBankNamedPage: (_) =>
      const BankAccountFormScreen(),
  AppRoutes.documentRegistrationConsentNamedPage: (_) => const ConsentScreen(),
  AppRoutes.fcmDebugNamedPage: (_) => const FcmDebugScreen(),
};

/// The paths [resolveDeepLink] will accept.
Set<String> get deepLinkableRoutes => deepLinkScreens.keys.toSet();

/// Schemes whose host is a domain name rather than part of the route.
const Set<String> _webSchemes = {'http', 'https'};

/// Turns an incoming link into a route, or null when it names nothing we serve.
///
/// Where the route starts depends on the scheme. Under `massdrive://` there is
/// no domain, so `massdrive://home` puts "home" in the URI's *host*, while the
/// three-slash spelling leaves the host empty and puts it in the path — both
/// are accepted. Under http(s) the host is the domain and only the path counts,
/// which is what makes this work unchanged if App Links / Universal Links are
/// added later.
///
///     massdrive://home                        -> /home
///     massdrive:///home                       -> /home
///     massdrive://document-registration/consent
///                                             -> /document-registration/consent
///     massdrive://home?tab=2                  -> /home?tab=2
///     https://driver.example.com/setting      -> /setting
///
/// Query strings are preserved for the destination to read; the allowlist is
/// checked against the path alone. A trailing slash is tolerated. Anything
/// unrecognised returns null rather than guessing — callers fall back to home.
@visibleForTesting
String? resolveDeepLink(Uri uri) {
  final hostIsRouteSegment =
      uri.host.isNotEmpty && !_webSchemes.contains(uri.scheme);

  var route = hostIsRouteSegment ? '/${uri.host}${uri.path}' : uri.path;
  if (route.length > 1 && route.endsWith('/')) {
    route = route.substring(0, route.length - 1);
  }
  if (!deepLinkableRoutes.contains(route)) return null;

  return uri.hasQuery ? '$route?${uri.query}' : route;
}

/// Opens screens from `massdrive://` links (see [deepLinkableRoutes]).
///
/// A link that arrives while the driver is logged out is held rather than
/// dropped: the router would bounce it straight to `/login` and the
/// destination would be lost, so it is replayed once [SessionNotifier] reports
/// a session. Only the most recent link is kept — an older, superseded one is
/// not worth restoring.
class DeepLinkService {
  DeepLinkService._()
    : _initialLink = _appLinks.getInitialLink,
      _linkStream = (() => _appLinks.uriLinkStream),
      _navigate = _goTo;

  /// Builds a service over fakes, so the routing rules can be tested without
  /// the platform channel or a live router.
  @visibleForTesting
  DeepLinkService.withSources({
    required InitialLink initialLink,
    required LinkStream linkStream,
    required Navigate navigate,
  }) : _initialLink = initialLink,
       _linkStream = linkStream,
       _navigate = navigate;

  static final DeepLinkService instance = DeepLinkService._();

  final InitialLink _initialLink;
  final LinkStream _linkStream;
  final Navigate _navigate;

  StreamSubscription<Uri>? _sub;
  bool _started = false;
  String? _pendingRoute;

  /// Begin handling links. Call once, after the router exists; repeat calls are
  /// no-ops.
  ///
  /// The launch link is read before subscribing, because the stream replays it
  /// on some platforms and the app would otherwise act on it twice. Reading it
  /// first makes the duplicate identifiable: the very first stream event is
  /// dropped when it matches. Only that one event — tapping the same link
  /// again later is a real request and is honoured.
  Future<void> start() async {
    if (_started) return;
    _started = true;

    SessionNotifier.instance.addListener(_onSessionChanged);

    Uri? launchLink;
    try {
      launchLink = await _initialLink();
    } catch (e) {
      debugPrint('DeepLink: initial link failed: $e');
    }
    if (launchLink != null) _handle(launchLink);

    var replayOfLaunch = launchLink;
    _sub = _linkStream().listen(
      (uri) {
        if (replayOfLaunch == uri) {
          debugPrint('DeepLink: ignoring stream replay of the launch link');
          replayOfLaunch = null;
          return;
        }
        replayOfLaunch = null;
        _handle(uri);
      },
      // A malformed link from another app must not take the zone down.
      onError: (Object e) => debugPrint('DeepLink: stream error: $e'),
    );
  }

  /// Detach. Only needed so tests don't leak listeners onto the
  /// [SessionNotifier] singleton between cases.
  @visibleForTesting
  Future<void> stop() async {
    if (!_started) return;
    _started = false;
    SessionNotifier.instance.removeListener(_onSessionChanged);
    await _sub?.cancel();
    _sub = null;
    _pendingRoute = null;
  }

  void _handle(Uri uri) {
    debugPrint('DeepLink: received $uri');
    final route = resolveDeepLink(uri);
    if (route == null) {
      debugPrint('DeepLink: no route for $uri, ignoring');
      return;
    }

    if (!SessionNotifier.instance.isAuthenticated) {
      debugPrint('DeepLink: holding $route until sign-in');
      _pendingRoute = route;
      return;
    }
    _navigate(route);
  }

  void _onSessionChanged() {
    if (!SessionNotifier.instance.isAuthenticated) {
      // Signed out before the link could be used — it belonged to that session.
      _pendingRoute = null;
      return;
    }
    final route = _pendingRoute;
    if (route == null) return;
    _pendingRoute = null;
    debugPrint('DeepLink: replaying $route after sign-in');
    _navigate(route);
  }
}

final AppLinks _appLinks = AppLinks();


/// Opens a deep-linked screen on the root navigator.
///
/// Deliberately not go_router. This app's go_router location does not reliably
/// describe what is on screen — some flows navigate with `go` and dismiss with
/// `Navigator.pop`, and `errorBuilder` renders HomeScreen so a bad location
/// still looks right. A `push` onto that state was repeatedly accepted and
/// then discarded, leaving the driver on home with the log claiming success.
///
/// Pushing a route onto the root navigator is what the app already does to open
/// these screens from home (see AppNavigator.push), so it behaves identically —
/// including the app bar's `Navigator.maybePop`, which now has a page to pop
/// back to.
void _goTo(String route) => _openWhenReady(route, 0);

/// How long to wait for the navigator to exist.
///
/// A link that launches the app is handled from `main` before `runApp`, so
/// there is no navigator yet, and a cold debug start spends several seconds in
/// Firebase init, DI and storage before there is one.
const int _settleAttempts = 200;
const Duration _settleInterval = Duration(milliseconds: 100);

/// Consecutive unchanged readings before the app counts as settled.
const int _stableReadings = 10; // 1s at _settleInterval

void _openWhenReady(
  String route,
  int attempt, {
  String? lastPath,
  int stable = 0,
}) {
  final navigator = AppRouter.router.routerDelegate.navigatorKey.currentState;
  final path = _currentLocation();

  // Waiting for a navigator is not enough. Launching by link restarts the
  // activity, and the navigator from the previous run is still there while the
  // app replays its startup — splash then calls `go` about two seconds later
  // and wipes whatever was pushed in the meantime. Wait for the location to
  // hold still instead, which covers both a cold start and that replay.
  final ready = navigator != null &&
      path != null &&
      path != AppRoutes.splashNamedPage &&
      path == lastPath;
  final nextStable = ready ? stable + 1 : 0;

  if (nextStable < _stableReadings && attempt < _settleAttempts) {
    if (attempt == 0) debugPrint('DeepLink: waiting for the app to settle');
    Future.delayed(
      _settleInterval,
      () => _openWhenReady(
        route,
        attempt + 1,
        lastPath: path,
        stable: nextStable,
      ),
    );
    return;
  }
  if (navigator == null) {
    debugPrint('DeepLink: no navigator, dropping $route');
    return;
  }

  final target = _pathOf(route);

  // Home is the screen everything else sits on; pushing a second copy above it
  // would leave a back arrow that goes nowhere useful.
  if (target == AppRoutes.homeNamedPage) {
    debugPrint('DeepLink: going home (waited ${attempt * 100}ms)');
    AppRouter.router.go(AppRoutes.homeNamedPage);
    return;
  }

  final builder = deepLinkScreens[target];
  if (builder == null) {
    debugPrint('DeepLink: no screen registered for $target, dropping');
    return;
  }

  debugPrint('DeepLink: opening $target from $path (waited ${attempt * 100}ms)');
  navigator.push(MaterialPageRoute<void>(builder: builder));
}

String _pathOf(String route) {
  final q = route.indexOf('?');
  return q == -1 ? route : route.substring(0, q);
}

/// The router's current path, or null before it has resolved a route.
///
/// Read off `currentConfiguration`, not `GoRouter.state`, which is
/// `currentConfiguration.last` and throws "Bad state: No element" on the empty
/// configuration a link handled at launch runs into.
String? _currentLocation() {
  final config = AppRouter.router.routerDelegate.currentConfiguration;
  return config.isEmpty ? null : config.uri.path;
}
