import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:massdrive/core/auth/session_notifier.dart';
import 'package:massdrive/features/call/data/call_api_service.dart';
import 'package:massdrive/features/call/data/callkit_system_ui.dart';
import 'package:massdrive/features/dependency_injection.dart';

/// Keeps the backend's PushKit (VoIP) token in sync with the signed-in
/// driver, iOS only: registered after every login and app start while logged
/// in and whenever PushKit hands out a new token; deleted on logout. The
/// token itself comes from AppDelegate.swift's PushKit delegate.
class VoipTokenRegistrar {
  VoipTokenRegistrar._();

  static final VoipTokenRegistrar instance = VoipTokenRegistrar._();

  /// An Xcode (Debug, aps-environment development) build talks to the APNs
  /// sandbox; Release / TestFlight to production.
  static const bool _sandbox = kDebugMode;

  bool _started = false;
  String? _registered;

  void start() {
    if (_started || defaultTargetPlatform != TargetPlatform.iOS) return;
    _started = true;
    SessionNotifier.instance.addListener(_onSessionChanged);
    CallKitSystemUi.instance.voipTokenUpdates.listen((_) {
      if (SessionNotifier.instance.isAuthenticated) unawaited(_register());
    });
    _onSessionChanged();
    // On a first launch PushKit can hand out the token before Dart listens.
    Future.delayed(const Duration(seconds: 5), _onSessionChanged);
  }

  /// Logout: drop the token before the session goes, while the request can
  /// still authenticate.
  Future<void> unregister() async {
    if (!_started) return;
    final token = _registered ?? await _token();
    _registered = null;
    if (token == null) return;
    try {
      await getIt<CallApiService>().deleteVoipToken(token, sandbox: _sandbox);
    } catch (e) {
      debugPrint('VoIP token delete failed: $e');
    }
  }

  void _onSessionChanged() {
    if (SessionNotifier.instance.isAuthenticated) {
      unawaited(_register());
    } else {
      // The next sign-in must bind the token to that driver again.
      _registered = null;
    }
  }

  Future<void> _register() async {
    final token = await _token();
    if (token == null || token == _registered) return;
    try {
      await getIt<CallApiService>().registerVoipToken(token, sandbox: _sandbox);
      _registered = token;
    } catch (e) {
      debugPrint('VoIP token register failed: $e');
    }
  }

  Future<String?> _token() async {
    try {
      final token = await FlutterCallkitIncoming.getDevicePushTokenVoIP();
      return (token == null || token.isEmpty) ? null : token;
    } catch (_) {
      return null;
    }
  }
}
