import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:massdrive/core/auth/session_notifier.dart';
import 'package:massdrive/core/constants/app_routes.dart';
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
const Set<String> deepLinkableRoutes = {
  AppRoutes.homeNamedPage,
  AppRoutes.incomeNamedPage,
  AppRoutes.cashWalletNamedPage,
  AppRoutes.creditWalletNamedPage,
  AppRoutes.profileNamedPage,
  AppRoutes.editProfileNamedPage,
  AppRoutes.serviceTypeNamedPage,
  AppRoutes.settingNamedPage,
  '/messenger-history',
  AppRoutes.documentRegistrationChecklistNamedPage,
  AppRoutes.documentRegistrationProfileNamedPage,
  AppRoutes.documentRegistrationUploadNamedPage,
  AppRoutes.documentRegistrationVehicleNamedPage,
  AppRoutes.documentRegistrationBankNamedPage,
  AppRoutes.documentRegistrationConsentNamedPage,
  AppRoutes.fcmDebugNamedPage,
};

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

/// Opens a deep-linked route with somewhere to go back to.
///
/// Pushed, not `go`: `go` replaces the stack, which left the destination as the
/// only page, so the app bar's `Navigator.maybePop` had nothing to pop and the
/// back arrow did nothing. Pushing puts the screen above whatever the app was
/// showing — home on a cold start, or the driver's current screen — and back
/// returns there.
///
/// The wait matters as much as the push. On a cold start the splash screen
/// holds the stack for a couple of seconds and then calls `go` itself; anything
/// pushed before that hand-off is discarded by it, which looks exactly like the
/// link doing nothing.
void _goTo(String route) => _pushOnceSettled(route, 0);

/// Splash resolves in ~2s; poll a little beyond that, then push regardless
/// rather than swallow the link.
const int _settleAttempts = 40;
const Duration _settleInterval = Duration(milliseconds: 100);

void _pushOnceSettled(String route, int attempt) {
  final router = AppRouter.router;
  final onSplash = router.state.uri.path == AppRoutes.splashNamedPage;

  if (onSplash && attempt < _settleAttempts) {
    Future.delayed(
      _settleInterval,
      () => _pushOnceSettled(route, attempt + 1),
    );
    return;
  }
  router.push(route);
}
