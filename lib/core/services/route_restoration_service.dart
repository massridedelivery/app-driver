import 'package:go_router/go_router.dart';
import 'package:get_storage/get_storage.dart';
import 'package:massdrive/core/constants/app_routes.dart';

/// Remembers the route the user was last on so the app can return there after
/// the OS kills the process in the background, instead of always resetting to
/// the home screen.
///
/// Only "browsable" screens are persisted. Auth/splash flow and transient
/// action screens that need runtime context (`extra` params) to be meaningful
/// are never restored into.
class RouteRestorationService {
  RouteRestorationService._();

  static final RouteRestorationService instance = RouteRestorationService._();

  static const String _key = 'last_route';

  /// Null until [init] succeeds. When null, restoration is silently disabled so
  /// a storage failure can never break app startup.
  GetStorage? _box;

  /// Best-effort storage init. If it throws, restoration is disabled but the
  /// app still boots normally.
  Future<void> init() async {
    try {
      await GetStorage.init();
      _box = GetStorage();
    } catch (_) {
      _box = null;
    }
  }

  /// Paths we never save/restore.
  static const Set<String> _nonRestorable = {
    AppRoutes.splashNamedPage,
    AppRoutes.loginNamedPage,
    AppRoutes.emailLoginNamedPage,
    AppRoutes.registerNamedPage,
    AppRoutes.otpNamedPage,
    '/payment',
    '/job-live',
  };

  String? _lastSaved;

  bool _isRestorable(String location) {
    if (location.isEmpty) return false;
    final path = Uri.parse(location).path;
    // Empty/root paths appear transiently (e.g. before the first match
    // resolves) and are not real destinations.
    if (path.isEmpty || path == '/') return false;
    return !_nonRestorable.contains(path);
  }

  /// Starts listening to the router and persists the current location whenever
  /// it changes. No-op if storage init failed. Safe to call once during startup.
  void attach(GoRouter router) {
    if (_box == null) return;
    router.routerDelegate.addListener(() {
      _save(router.routerDelegate.currentConfiguration.uri.toString());
    });
  }

  void _save(String location) {
    final box = _box;
    if (box == null) return;
    if (location == _lastSaved) return;
    if (!_isRestorable(location)) return;
    _lastSaved = location;
    box.write(_key, location);
  }

  /// The route to restore to, or `null` if there is nothing safe to restore.
  String? get lastRoute {
    final box = _box;
    if (box == null) return null;
    final saved = box.read<String>(_key);
    if (saved == null) return null;
    return _isRestorable(saved) ? saved : null;
  }

  /// Clears the saved route (e.g. on logout).
  Future<void> clear() async => _box?.remove(_key);
}
