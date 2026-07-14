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

  final GetStorage _box = GetStorage();

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
  /// it changes. Safe to call once during app startup.
  void attach(GoRouter router) {
    router.routerDelegate.addListener(() {
      _save(router.routerDelegate.currentConfiguration.uri.toString());
    });
  }

  void _save(String location) {
    if (location == _lastSaved) return;
    if (!_isRestorable(location)) return;
    _lastSaved = location;
    _box.write(_key, location);
  }

  /// The route to restore to, or `null` if there is nothing safe to restore.
  String? get lastRoute {
    final saved = _box.read<String>(_key);
    if (saved == null) return null;
    return _isRestorable(saved) ? saved : null;
  }

  /// Clears the saved route (e.g. on logout).
  Future<void> clear() => _box.remove(_key);
}
