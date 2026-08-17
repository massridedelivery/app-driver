import 'package:flutter/foundation.dart';
import 'package:massdrive/core/data/secure_storage/secure_storage_manager.dart';

/// Single source of truth for whether a driver session is currently active.
///
/// Both the router (`GoRouter.refreshListenable` + `redirect`) and the API layer
/// talk to this notifier, so *any* place that invalidates the session — an
/// explicit logout, a failed token refresh, or a 401 on an authenticated
/// request — reactively pushes the app back to the login screen.
///
/// It is a plain singleton (not GetIt/Riverpod) on purpose: the Dio interceptor
/// can reach it without the circular dependency that previously left the
/// refresh-failure logout hook empty.
class SessionNotifier extends ChangeNotifier {
  SessionNotifier._();

  static final SessionNotifier instance = SessionNotifier._();

  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  /// Update the in-memory auth flag. No-op (no listener churn) when unchanged.
  void setAuthenticated(bool value) {
    if (_isAuthenticated == value) return;
    _isAuthenticated = value;
    notifyListeners();
  }

  /// Wipe the stored session and flip to logged-out. Safe to call repeatedly
  /// and from anywhere (interceptor, API layer) — it clears secure storage so a
  /// dead token can't survive, then notifies the router to redirect to login.
  Future<void> notifySessionExpired() async {
    try {
      await SecureStorageManager().deleteAll();
    } finally {
      setAuthenticated(false);
    }
  }
}
