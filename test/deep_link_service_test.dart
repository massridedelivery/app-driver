import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/core/auth/session_notifier.dart';
import 'package:massdrive/core/services/deep_link_service.dart';

void main() {
  group('resolveDeepLink', () {
    test('accepts the host spelling of a route', () {
      expect(resolveDeepLink(Uri.parse('massdrive://home')), '/home');
      expect(resolveDeepLink(Uri.parse('massdrive://setting')), '/setting');
    });

    test('accepts the empty-host spelling too', () {
      // massdrive:///home — three slashes, so the route lands in the path.
      expect(resolveDeepLink(Uri.parse('massdrive:///home')), '/home');
    });

    test('handles a multi-segment route either way', () {
      const route = '/document-registration/consent';
      expect(
        resolveDeepLink(Uri.parse('massdrive://document-registration/consent')),
        route,
      );
      expect(
        resolveDeepLink(Uri.parse('massdrive:///document-registration/consent')),
        route,
      );
    });

    test('keeps the query for the destination to read', () {
      expect(resolveDeepLink(Uri.parse('massdrive://home?tab=2')), '/home?tab=2');
    });

    test('tolerates a trailing slash', () {
      expect(resolveDeepLink(Uri.parse('massdrive://home/')), '/home');
    });

    test('rejects live/offer screens, whose state is only in memory', () {
      // Opening these cold shows a spinner with no job behind it — the same
      // reason RouteRestorationService refuses to restore them.
      for (final route in [
        'incoming-job',
        'job-live',
        'food-live',
        'messenger-offer',
        'messenger-live',
        'payment',
      ]) {
        expect(
          resolveDeepLink(Uri.parse('massdrive://$route')),
          isNull,
          reason: '$route must not be reachable by link',
        );
      }
    });

    test('rejects auth screens', () {
      for (final route in ['login', 'email-login', 'register', 'otp_screen', 'splash']) {
        expect(resolveDeepLink(Uri.parse('massdrive://$route')), isNull,
            reason: '$route must not be reachable by link');
      }
    });

    test('rejects unknown routes rather than guessing', () {
      expect(resolveDeepLink(Uri.parse('massdrive://nope')), isNull);
      expect(resolveDeepLink(Uri.parse('massdrive://home/extra')), isNull);
      expect(resolveDeepLink(Uri.parse('massdrive://')), isNull);
    });

    test('is not fooled by a path that merely starts with a valid route', () {
      expect(resolveDeepLink(Uri.parse('massdrive://home-evil')), isNull);
    });

    test('resolves regardless of scheme, so https links work unchanged later', () {
      expect(
        resolveDeepLink(Uri.parse('https://driver.example.com/setting')),
        '/setting',
      );
    });
  });

  group('DeepLinkService', () {
    late List<String> navigated;
    late StreamController<Uri> links;
    late DeepLinkService service;
    Uri? initial;

    DeepLinkService build() => DeepLinkService.withSources(
      initialLink: () async => initial,
      linkStream: () => links.stream,
      navigate: navigated.add,
    );

    setUp(() {
      navigated = [];
      links = StreamController<Uri>.broadcast();
      initial = null;
      SessionNotifier.instance.setAuthenticated(false);
    });

    tearDown(() async {
      await service.stop();
      SessionNotifier.instance.setAuthenticated(false);
      await links.close();
    });

    test('navigates on a link received while signed in', () async {
      SessionNotifier.instance.setAuthenticated(true);
      service = build();
      await service.start();

      links.add(Uri.parse('massdrive://setting'));
      await pumpEventQueue();

      expect(navigated, ['/setting']);
    });

    test('follows the link the app was launched from', () async {
      SessionNotifier.instance.setAuthenticated(true);
      initial = Uri.parse('massdrive://income');

      service = build();
      await service.start();
      await pumpEventQueue();

      expect(navigated, ['/income']);
    });

    test('holds a link that arrives signed out, then replays it', () async {
      // Otherwise the router bounces it to /login and the destination is lost.
      service = build();
      await service.start();

      links.add(Uri.parse('massdrive://profile'));
      await pumpEventQueue();
      expect(navigated, isEmpty);

      SessionNotifier.instance.setAuthenticated(true);
      await pumpEventQueue();

      expect(navigated, ['/profile']);
    });

    test('keeps only the most recent held link', () async {
      service = build();
      await service.start();

      links.add(Uri.parse('massdrive://profile'));
      links.add(Uri.parse('massdrive://income'));
      await pumpEventQueue();

      SessionNotifier.instance.setAuthenticated(true);
      await pumpEventQueue();

      expect(navigated, ['/income']);
    });

    test('drops a held link if the driver never signs in', () async {
      service = build();
      await service.start();

      links.add(Uri.parse('massdrive://profile'));
      await pumpEventQueue();
      // A logged-out -> logged-out flip is a no-op, so force the listener the
      // way a real failed sign-in would: go live, then straight back out.
      SessionNotifier.instance.setAuthenticated(true);
      await pumpEventQueue();
      navigated.clear();
      SessionNotifier.instance.setAuthenticated(false);
      await pumpEventQueue();
      SessionNotifier.instance.setAuthenticated(true);
      await pumpEventQueue();

      expect(navigated, isEmpty, reason: 'the link belonged to the old session');
    });

    test('acts once when the stream replays the launch link', () async {
      // app_links re-emits the launch link on some platforms; acting on both
      // would navigate twice for a single tap.
      SessionNotifier.instance.setAuthenticated(true);
      initial = Uri.parse('massdrive://income');

      service = build();
      await service.start();
      links.add(Uri.parse('massdrive://income'));
      await pumpEventQueue();

      expect(navigated, ['/income']);
    });

    test('still honours the same link tapped again later', () async {
      SessionNotifier.instance.setAuthenticated(true);
      initial = Uri.parse('massdrive://income');

      service = build();
      await service.start();
      links.add(Uri.parse('massdrive://income')); // the replay — dropped
      await pumpEventQueue();
      links.add(Uri.parse('massdrive://income')); // a real second tap
      await pumpEventQueue();

      expect(navigated, ['/income', '/income']);
    });

    test('ignores an unroutable link instead of navigating anywhere', () async {
      SessionNotifier.instance.setAuthenticated(true);
      service = build();
      await service.start();

      links.add(Uri.parse('massdrive://incoming-job'));
      links.add(Uri.parse('massdrive://nope'));
      await pumpEventQueue();

      expect(navigated, isEmpty);
    });

    test('survives an error on the link stream', () async {
      SessionNotifier.instance.setAuthenticated(true);
      service = build();
      await service.start();

      links.addError(const FormatException('bad link'));
      await pumpEventQueue();
      links.add(Uri.parse('massdrive://home'));
      await pumpEventQueue();

      expect(navigated, ['/home']);
    });

    test('start is idempotent', () async {
      SessionNotifier.instance.setAuthenticated(true);
      service = build();
      await service.start();
      await service.start();

      links.add(Uri.parse('massdrive://home'));
      await pumpEventQueue();

      expect(navigated, ['/home'], reason: 'no duplicate subscription');
    });
  });
}
