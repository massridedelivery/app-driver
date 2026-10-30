import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/core/update/update_check.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _fallback = 'https://apps.apple.com/th/app/id6791101190';

class _FakeSources implements UpdateSources {
  _FakeSources({required this.reply});

  BackendReply reply;
  StoreUpdate? storeUpdate;
  String version = '1.0.1';
  int backendCalls = 0;

  @override
  Future<String> appVersion() async => version;

  @override
  Future<BackendReply> backend(String appVersion) async {
    backendCalls++;
    return reply;
  }

  @override
  Future<StoreUpdate?> store(String appVersion) async => storeUpdate;

  @override
  String get fallbackStoreUrl => _fallback;
}

VersionAnswer _answer(String status, {String? latest = '1.0.2'}) =>
    VersionAnswer.fromJson({
      'status': status,
      'latest_version': latest,
      'store_url': 'https://store.example/massdrive',
      'message': 'Please update',
      'message_th': 'กรุณาอัปเดต',
    });

void main() {
  group('isNewerVersion', () {
    test('compares each part as a number', () {
      expect(isNewerVersion('1.0.10', '1.0.9'), isTrue);
      expect(isNewerVersion('1.0.9', '1.0.10'), isFalse);
      expect(isNewerVersion('1.1', '1.0.9'), isTrue);
      expect(isNewerVersion('2.0.0', '1.9.9'), isTrue);
    });

    test('ignores the build number', () {
      expect(isNewerVersion('1.0.1+40', '1.0.1+16'), isFalse);
      expect(isNewerVersion('1.0.2+1', '1.0.1+99'), isTrue);
    });

    test('equal versions and missing parts are not newer', () {
      expect(isNewerVersion('1.0.1', '1.0.1'), isFalse);
      expect(isNewerVersion('1.0', '1.0.0'), isFalse);
      expect(isNewerVersion('1.0.0.1', '1.0'), isTrue);
    });

    test('a non-numeric part counts as 0', () {
      expect(isNewerVersion('1.0.x', '1.0.0'), isFalse);
      expect(isNewerVersion('1.0.1', '1.0.beta'), isTrue);
    });
  });

  group('decideUpdate', () {
    UpdatePrompt? decide(
      BackendReply backend, {
      VersionAnswer? cached,
      String? cachedFor,
      StoreUpdate? store,
    }) => decideUpdate(
      appVersion: '1.0.1',
      backend: backend,
      fallbackStoreUrl: _fallback,
      cached: cached,
      cachedForVersion: cachedFor,
      store: store,
    );

    const newerOnStore = StoreUpdate(
      storeUrl: 'https://apps.apple.com/app/x',
      storeVersion: '1.0.3',
    );

    test('FORCE_UPDATE blocks with the backend message and store url', () {
      final p = decide(BackendReply.answered(_answer('FORCE_UPDATE')))!;
      expect(p.force, isTrue);
      expect(p.storeUrl, 'https://store.example/massdrive');
      expect(p.latestVersion, '1.0.2');
      expect(p.messageFor(thai: true), 'กรุณาอัปเดต');
      expect(p.messageFor(thai: false), 'Please update');
    });

    test('FORCE_UPDATE without a store url falls back to the store page', () {
      final answer = VersionAnswer.fromJson({'status': 'FORCE_UPDATE'});
      expect(decide(BackendReply.answered(answer))!.storeUrl, _fallback);
    });

    test('SUGGEST_UPDATE suggests, never blocks', () {
      final p = decide(BackendReply.answered(_answer('SUGGEST_UPDATE')))!;
      expect(p.force, isFalse);
    });

    test('OK with nothing newer on the store: nothing to show', () {
      expect(decide(BackendReply.answered(_answer('OK'))), isNull);
    });

    test('an unknown status counts as OK', () {
      expect(decide(BackendReply.answered(_answer('MAYBE'))), isNull);
    });

    test('OK but the store is newer: suggest only', () {
      final p = decide(
        BackendReply.answered(_answer('OK')),
        store: newerOnStore,
      )!;
      expect(p.force, isFalse);
      expect(p.latestVersion, '1.0.3');
      expect(p.storeUrl, 'https://apps.apple.com/app/x');
    });

    test('backend unreachable but the store is newer: suggest only', () {
      final p = decide(const BackendReply.offline(), store: newerOnStore)!;
      expect(p.force, isFalse);
    });

    test('backend 404 (not shipped yet): no block', () {
      expect(decide(const BackendReply.refused()), isNull);
    });

    test('backend 404 ignores a cached FORCE: the server did answer', () {
      expect(
        decide(
          const BackendReply.refused(),
          cached: _answer('FORCE_UPDATE'),
          cachedFor: '1.0.1',
        ),
        isNull,
      );
    });

    test('offline with a cached FORCE for this version: still blocks', () {
      final p = decide(
        const BackendReply.offline(),
        cached: _answer('FORCE_UPDATE'),
        cachedFor: '1.0.1',
      )!;
      expect(p.force, isTrue);
      expect(p.messageFor(thai: true), 'กรุณาอัปเดต');
    });

    test('offline with a cached FORCE for another version: no block', () {
      expect(
        decide(
          const BackendReply.offline(),
          cached: _answer('FORCE_UPDATE'),
          cachedFor: '1.0.0',
        ),
        isNull,
      );
    });

    test('offline with a cached OK: no block', () {
      expect(
        decide(
          const BackendReply.offline(),
          cached: _answer('OK'),
          cachedFor: '1.0.1',
        ),
        isNull,
      );
    });

    test('offline with no cache: no block', () {
      expect(decide(const BackendReply.offline()), isNull);
    });
  });

  group('shouldShowSuggestion', () {
    final now = DateTime(2026, 10, 30, 12);

    test('never shown: show', () {
      expect(shouldShowSuggestion(version: '1.0.2', now: now), isTrue);
    });

    test('same version within 24 h: wait', () {
      expect(
        shouldShowSuggestion(
          version: '1.0.2',
          now: now,
          lastVersion: '1.0.2',
          lastShownAt: now.subtract(const Duration(hours: 23)),
        ),
        isFalse,
      );
    });

    test('same version after 24 h: show again', () {
      expect(
        shouldShowSuggestion(
          version: '1.0.2',
          now: now,
          lastVersion: '1.0.2',
          lastShownAt: now.subtract(const Duration(hours: 24)),
        ),
        isTrue,
      );
    });

    test('a newer version shows right away', () {
      expect(
        shouldShowSuggestion(
          version: '1.0.3',
          now: now,
          lastVersion: '1.0.2',
          lastShownAt: now.subtract(const Duration(minutes: 5)),
        ),
        isTrue,
      );
    });
  });

  group('UpdateCheck', () {
    late DateTime now;
    late _FakeSources sources;
    late UpdateCheck check;

    UpdateCheck make({bool enabled = true}) =>
        UpdateCheck(sources: sources, clock: () => now, enabled: enabled);

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      now = DateTime(2026, 10, 30, 9);
      sources = _FakeSources(
        reply: BackendReply.answered(_answer('FORCE_UPDATE')),
      );
      check = make();
    });

    test('FORCE_UPDATE sets forced and tells the router', () async {
      var notified = 0;
      check.addListener(() => notified++);
      await check.check();
      expect(check.forced?.force, isTrue);
      expect(check.suggestion.value, isNull);
      expect(notified, 1);
    });

    test('a later OK lifts the block', () async {
      await check.check();
      sources.reply = BackendReply.answered(_answer('OK'));
      await check.check();
      expect(check.forced, isNull);
    });

    test(
      'offline after a FORCE answer keeps blocking (from the cache)',
      () async {
        await check.check();
        final fresh = make();
        sources.reply = const BackendReply.offline();
        await fresh.check();
        expect(fresh.forced?.force, isTrue);
      },
    );

    test('offline after an OK answer does not block', () async {
      sources.reply = BackendReply.answered(_answer('OK'));
      await check.check();
      final fresh = make();
      sources.reply = const BackendReply.offline();
      await fresh.check();
      expect(fresh.forced, isNull);
    });

    test('the cached FORCE is for the version that got it', () async {
      await check.check();
      final prefs = await SharedPreferences.getInstance();
      final cached = jsonDecode(prefs.getString('update_check.answer')!);
      expect(cached['app_version'], '1.0.1');

      sources
        ..version = '1.0.2'
        ..reply = const BackendReply.offline();
      final updated = make();
      await updated.check();
      expect(updated.forced, isNull);
    });

    test('SUGGEST_UPDATE shows once per 24 h for the same version', () async {
      sources.reply = BackendReply.answered(_answer('SUGGEST_UPDATE'));
      await check.check();
      final first = check.suggestion.value;
      expect(first, isNotNull);
      expect(check.forced, isNull);
      await check.markSuggestionShown(first!);
      expect(check.suggestion.value, isNull);

      now = now.add(const Duration(hours: 7));
      await check.check();
      expect(check.suggestion.value, isNull, reason: 'shown 7 h ago');

      now = now.add(const Duration(hours: 17));
      await check.check();
      expect(check.suggestion.value, isNotNull, reason: '24 h passed');
    });

    test('a store-only suggestion never blocks', () async {
      sources
        ..reply = const BackendReply.refused()
        ..storeUpdate = const StoreUpdate(
          storeUrl: 'https://play.google.com/store/apps/details?id=x',
          playImmediate: true,
        );
      await check.check();
      expect(check.forced, isNull);
      expect(check.suggestion.value?.playImmediate, isTrue);
    });

    test('resume re-checks only after 6 h', () async {
      await check.check();
      expect(sources.backendCalls, 1);
      now = now.add(const Duration(hours: 5, minutes: 59));
      await check.checkIfStale();
      expect(sources.backendCalls, 1);
      now = now.add(const Duration(minutes: 1));
      await check.checkIfStale();
      expect(sources.backendCalls, 2);
    });

    test('disabled (debug/web builds): never asks, never blocks', () async {
      final off = make(enabled: false);
      await off.check();
      expect(sources.backendCalls, 0);
      expect(off.forced, isNull);
    });

    test('a throwing source never blocks', () async {
      final broken = UpdateCheck(
        sources: _ThrowingSources(),
        clock: () => now,
        enabled: true,
      );
      await broken.check();
      expect(broken.forced, isNull);
      expect(broken.suggestion.value, isNull);
    });
  });
}

class _ThrowingSources implements UpdateSources {
  @override
  Future<String> appVersion() async => throw StateError('no package info');

  @override
  Future<BackendReply> backend(String appVersion) async =>
      throw StateError('unreachable');

  @override
  Future<StoreUpdate?> store(String appVersion) async => null;

  @override
  String get fallbackStoreUrl => _fallback;
}
