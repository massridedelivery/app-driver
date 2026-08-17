import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/core/auth/session_notifier.dart';
import 'package:massdrive/core/services/push_token_registrar.dart';

void main() {
  late List<String> posted;
  late StreamController<String> refreshes;
  late PushTokenRegistrar registrar;
  String? currentToken;

  /// Builds a registrar over fakes. [onPost] lets a case make the POST fail.
  PushTokenRegistrar build({Future<void> Function(String)? onPost}) {
    return PushTokenRegistrar.withSources(
      acquireToken: () async => currentToken,
      tokenRefreshes: () => refreshes.stream,
      postToken: (token) async {
        if (onPost != null) await onPost(token);
        posted.add(token);
      },
    );
  }

  setUp(() {
    posted = [];
    refreshes = StreamController<String>.broadcast();
    currentToken = 'token-a';
    // The notifier is a singleton shared across cases; every test starts
    // logged out, matching a cold launch.
    SessionNotifier.instance.setAuthenticated(false);
  });

  tearDown(() async {
    registrar.stop();
    SessionNotifier.instance.setAuthenticated(false);
    await refreshes.close();
  });

  test('registers on a fresh login, without a cold start', () async {
    // The bug this guards: registration used to live in the splash-only
    // startup controller, which had already returned "logged out" and been
    // disposed by the time the driver signed in — so a first login registered
    // nothing until the app was killed and reopened.
    registrar = build()..start();
    await pumpEventQueue();
    expect(posted, isEmpty, reason: 'nothing to register while logged out');

    SessionNotifier.instance.setAuthenticated(true);
    await pumpEventQueue();

    expect(posted, ['token-a']);
  });

  test('registers at start when the session is already live (cold start)',
      () async {
    SessionNotifier.instance.setAuthenticated(true);

    registrar = build()..start();
    await pumpEventQueue();

    expect(posted, ['token-a']);
  });

  test('does not re-post an unchanged token', () async {
    registrar = build()..start();
    SessionNotifier.instance.setAuthenticated(true);
    await pumpEventQueue();

    // A redundant flip to the same value is a no-op in SessionNotifier, so
    // drive the listener the way a real re-auth would: log out and back in.
    refreshes.add('token-a');
    await pumpEventQueue();

    expect(posted, ['token-a']);
  });

  test('re-registers when a different driver signs in on the same device',
      () async {
    registrar = build()..start();
    SessionNotifier.instance.setAuthenticated(true);
    await pumpEventQueue();

    SessionNotifier.instance.setAuthenticated(false);
    await pumpEventQueue();
    SessionNotifier.instance.setAuthenticated(true);
    await pumpEventQueue();

    // Same token, but it must be re-bound to the newly signed-in driver.
    expect(posted, ['token-a', 'token-a']);
  });

  test('forwards a rotated token while signed in', () async {
    registrar = build()..start();
    SessionNotifier.instance.setAuthenticated(true);
    await pumpEventQueue();

    refreshes.add('token-b');
    await pumpEventQueue();

    expect(posted, ['token-a', 'token-b']);
  });

  test('ignores a token rotation that lands after logout', () async {
    registrar = build()..start();
    SessionNotifier.instance.setAuthenticated(true);
    await pumpEventQueue();

    SessionNotifier.instance.setAuthenticated(false);
    await pumpEventQueue();
    refreshes.add('token-b');
    await pumpEventQueue();

    expect(posted, ['token-a'], reason: 'no session to bind the token to');
  });

  test('a failing POST is contained and retried on the next login', () async {
    var fail = true;
    registrar = build(
      onPost: (_) async {
        if (fail) throw StateError('backend down');
      },
    )..start();

    SessionNotifier.instance.setAuthenticated(true);
    await pumpEventQueue();
    expect(posted, isEmpty);

    fail = false;
    SessionNotifier.instance.setAuthenticated(false);
    await pumpEventQueue();
    SessionNotifier.instance.setAuthenticated(true);
    await pumpEventQueue();

    expect(posted, ['token-a']);
  });

  test('registers nothing when no token is available', () async {
    currentToken = null;

    registrar = build()..start();
    SessionNotifier.instance.setAuthenticated(true);
    await pumpEventQueue();

    expect(posted, isEmpty);
  });

  test('retry() registers once permission is granted mid-session', () async {
    // Denied permission yields no token, so signing in registers nothing.
    currentToken = null;
    registrar = build()..start();
    SessionNotifier.instance.setAuthenticated(true);
    await pumpEventQueue();
    expect(posted, isEmpty);

    // The driver enables notifications in system settings; the setting screen
    // sees the resume and calls retry().
    currentToken = 'token-a';
    await registrar.retry();
    await pumpEventQueue();

    expect(posted, ['token-a']);
  });

  test('retry() does nothing while logged out', () async {
    registrar = build()..start();

    await registrar.retry();
    await pumpEventQueue();

    expect(posted, isEmpty);
  });
}
