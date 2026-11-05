import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/core/auth/session_notifier.dart';
import 'package:massdrive/features/app_popup/data/popup_store.dart';
import 'package:massdrive/features/app_popup/domain/app_popup.dart';
import 'package:massdrive/features/app_popup/presentation/app_popups.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _body = {
  'items': [
    {
      'id': 'a',
      'version': 3,
      'image_url': 'https://media.example.com/a.jpg',
      'action': {
        'type': 'deeplink',
        'value': '/promos/NY50',
        'button_text': 'ดูรายละเอียด',
      },
      'end_at': '2026-12-31T16:59:59Z',
    },
    {
      'id': 'b',
      'version': 1,
      'image_url': 'https://media.example.com/b.png',
      'action': null,
      'end_at': null,
    },
    // Unusable: no image.
    {'id': 'c', 'version': 1, 'image_url': ''},
  ],
  'server_time': '2026-11-05T09:12:44Z',
};

void main() {
  group('parsing', () {
    test('items in order, unusable ones dropped', () {
      final items = AppPopup.listFrom(_body);
      expect(items.map((p) => p.id), ['a', 'b']);
      expect(items.first.action!.type, PopupActionType.deeplink);
      expect(items.first.action!.buttonText, 'ดูรายละเอียด');
      expect(items.last.action, isNull);
    });

    test('anything but a map with items is no pop-up', () {
      expect(AppPopup.listFrom(null), isEmpty);
      expect(AppPopup.listFrom('oops'), isEmpty);
      expect(AppPopup.listFrom({'items': null}), isEmpty);
    });
  });

  group('dismissal rule', () {
    final items = AppPopup.listFrom(_body);
    final a = items[0];

    test('the first item not suppressed', () {
      expect(PopupDismissals({}).next(items)?.id, 'a');
      expect(PopupDismissals({'a': 3}).next(items)?.id, 'b');
    });

    test('✕ unticked: this session only', () {
      final d = PopupDismissals({});
      expect(d.close(a, const PopupOutcome(dontShowAgain: false)), isFalse);
      expect(d.dismissed, isEmpty);
      expect(d.next(items)?.id, 'b');
      // Next cold start: a fresh session set, so it shows again.
      expect(PopupDismissals(d.dismissed).next(items)?.id, 'a');
    });

    test('✕ ticked: stored until a new version', () {
      final d = PopupDismissals({});
      expect(d.close(a, const PopupOutcome(dontShowAgain: true)), isTrue);
      expect(d.dismissed, {'a': 3});
      expect(PopupDismissals(d.dismissed).next(items)?.id, 'b');
    });

    test('an edited pop-up (new version) shows again', () {
      expect(PopupDismissals({'a': 2}).next(items)?.id, 'a');
    });

    test('entries for pop-ups no longer live are dropped', () {
      final d = PopupDismissals({'a': 3, 'gone': 1});
      expect(d.prune(items), isTrue);
      expect(d.dismissed, {'a': 3});
      expect(d.prune(items), isFalse);
    });
  });

  group('on screen', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      SessionNotifier.instance.setAuthenticated(true);
    });

    Future<BuildContext> home(WidgetTester t) async {
      late BuildContext ctx;
      await t.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (c) {
              ctx = c;
              return const Scaffold(body: Text('home'));
            },
          ),
        ),
      );
      return ctx;
    }

    AppPopups make(List<Map<String, dynamic>> items, {List<int>? calls}) =>
        AppPopups(
          fetch: () async {
            calls?.add(1);
            return AppPopup.listFrom({'items': items});
          },
          precache: (_, _) async => true,
        );

    final b = (_body['items'] as List)[1] as Map<String, dynamic>;

    testWidgets('ticked ✕ is remembered on the device', (t) async {
      final ctx = await home(t);
      final popups = make([b]);
      final done = popups.maybeShow(ctx);
      await t.pump();
      await t.pump();
      expect(find.text('ไม่แสดงหน้านี้ในครั้งถัดไป'), findsOneWidget);
      // No action → no button.
      expect(find.byType(FilledButton), findsNothing);

      await t.tap(find.text('ไม่แสดงหน้านี้ในครั้งถัดไป'));
      await t.pump();
      await t.tap(find.byTooltip('ปิด'));
      await t.pumpAndSettle();
      await done;
      final prefs = await SharedPreferences.getInstance();
      expect(jsonDecode(prefs.getString(PopupStore.key)!), {'b': 1});
    });

    testWidgets('the backdrop closes it like ✕; one pop-up per launch', (
      t,
    ) async {
      final ctx = await home(t);
      final calls = <int>[];
      final popups = make([b], calls: calls);
      final done = popups.maybeShow(ctx);
      await t.pump();
      await t.pump();
      await t.tapAt(const Offset(5, 5));
      await t.pumpAndSettle();
      await done;
      expect(find.text('ไม่แสดงหน้านี้ในครั้งถัดไป'), findsNothing);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(PopupStore.key), isNull);

      // Back in the foreground: nothing more this launch.
      await popups.maybeShow(ctx);
      await t.pump();
      expect(find.text('ไม่แสดงหน้านี้ในครั้งถัดไป'), findsNothing);
    });

    testWidgets('a fetch error means no pop-up', (t) async {
      final ctx = await home(t);
      final popups = AppPopups(
        fetch: () async => throw Exception('500'),
        precache: (_, _) async => true,
      );
      await popups.maybeShow(ctx);
      await t.pump();
      expect(find.text('ไม่แสดงหน้านี้ในครั้งถัดไป'), findsNothing);
    });

    testWidgets('signed out: never fetched', (t) async {
      SessionNotifier.instance.setAuthenticated(false);
      final ctx = await home(t);
      final calls = <int>[];
      await make([b], calls: calls).maybeShow(ctx);
      expect(calls, isEmpty);
    });
  });
}
