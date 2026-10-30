import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/core/auth/session_notifier.dart';
import 'package:massdrive/features/inbox/data/inbox_api.dart';
import 'package:massdrive/features/inbox/domain/inbox_message.dart';
import 'package:massdrive/features/inbox/presentation/inbox_controller.dart';
import 'package:massdrive/features/inbox/presentation/inbox_strings.dart';

InboxMessage _msg(String id, {bool read = false, Map<String, String>? data}) =>
    InboxMessage(
      id: id,
      title: 'title $id',
      body: 'body $id',
      data: data ?? const {},
      createdAt: DateTime(2026, 10, 30, 10),
      readAt: read ? DateTime(2026, 10, 30, 11) : null,
    );

DioException _http(int status) {
  final req = RequestOptions(path: '/api/notifications');
  return DioException(
    requestOptions: req,
    response: Response(requestOptions: req, statusCode: status),
  );
}

/// In-memory backend for the controller.
class _FakeApi implements InboxApi {
  _FakeApi(this.rows);

  List<InboxMessage> rows;
  Object? failDelete;
  Object? failList;
  bool failBulk = false;
  final calls = <String>[];

  int get _unread => rows.where((m) => !m.isRead).length;

  @override
  Future<InboxPage> list({int limit = 20, int offset = 0}) async {
    calls.add('list $limit $offset');
    if (failList != null) throw failList!;
    final page = rows.skip(offset).take(limit).toList();
    return InboxPage(items: page, unreadCount: _unread);
  }

  @override
  Future<void> markRead(String id) async {
    calls.add('read $id');
    rows = [for (final m in rows) m.id == id ? m.markedRead(DateTime(0)) : m];
  }

  @override
  Future<void> delete(String id) async {
    calls.add('delete $id');
    if (failDelete != null) throw failDelete!;
    rows = rows.where((m) => m.id != id).toList();
  }

  @override
  Future<void> deleteAll() async {
    calls.add('deleteAll');
    if (failBulk) throw _http(500);
    rows = [];
  }

  @override
  Future<void> readAll() async {
    calls.add('readAll');
    if (failBulk) throw _http(500);
    rows = [for (final m in rows) m.markedRead(DateTime(0))];
  }
}

void main() {
  late _FakeApi api;
  late ProviderContainer container;

  InboxController inbox() => container.read(inboxControllerProvider.notifier);
  InboxState state() => container.read(inboxControllerProvider);

  setUp(() {
    api = _FakeApi([_msg('a'), _msg('b'), _msg('c', read: true)]);
    container = ProviderContainer(
      overrides: [inboxApiProvider.overrideWithValue(api)],
    );
    SessionNotifier.instance.setAuthenticated(true);
  });

  tearDown(() => container.dispose());

  group('InboxController', () {
    test('refresh loads the first page and the unread count', () async {
      await inbox().refresh();
      expect(state().items.map((m) => m.id), ['a', 'b', 'c']);
      expect(state().unreadCount, 2);
      expect(state().loaded, isTrue);
      expect(state().hasMore, isFalse);
    });

    test('a failed first load shows the failed state, not empty', () async {
      api.failList = _http(500);
      await inbox().refresh();
      expect(state().failed, isTrue);
      expect(state().isEmpty, isFalse);
    });

    test('pages of 20 load more until a short page', () async {
      api.rows = [for (var i = 0; i < 25; i++) _msg('m$i')];
      await inbox().refresh();
      expect(state().items, hasLength(20));
      expect(state().hasMore, isTrue);
      await inbox().loadMore();
      expect(state().items, hasLength(25));
      expect(state().hasMore, isFalse);
      expect(api.calls, contains('list 20 20'));
    });

    test('refreshUnread reads only the count', () async {
      await inbox().refreshUnread();
      expect(state().unreadCount, 2);
      expect(state().items, isEmpty);
      expect(api.calls, ['list 1 0']);
    });

    test(
      'opening an unread message marks it read and drops the badge',
      () async {
        await inbox().refresh();
        await inbox().markRead(state().items.first);
        expect(state().items.first.isRead, isTrue);
        expect(state().unreadCount, 1);
        expect(api.calls, contains('read a'));
      },
    );

    test('swipe delete removes the row and refreshes the count', () async {
      await inbox().refresh();
      final ok = await inbox().delete(state().items.first);
      expect(ok, isTrue);
      expect(state().items.map((m) => m.id), ['b', 'c']);
      expect(state().unreadCount, 1);
      expect(api.calls.last, 'list 1 0');
    });

    test('a failed delete puts the row back where it was', () async {
      await inbox().refresh();
      api.failDelete = _http(500);
      final ok = await inbox().delete(state().items[1]);
      expect(ok, isFalse);
      expect(state().items.map((m) => m.id), ['a', 'b', 'c']);
      expect(state().unreadCount, 2);
    });

    test('deleting the last message leaves the empty state', () async {
      api.rows = [_msg('only')];
      await inbox().refresh();
      await inbox().delete(state().items.single);
      expect(state().isEmpty, isTrue);
      expect(state().unreadCount, 0);
    });

    test('delete all empties the inbox and the badge', () async {
      await inbox().refresh();
      expect(await inbox().deleteAll(), isTrue);
      expect(state().isEmpty, isTrue);
      expect(state().unreadCount, 0);
    });

    test('a failed delete all keeps the list', () async {
      await inbox().refresh();
      api.failBulk = true;
      expect(await inbox().deleteAll(), isFalse);
      expect(state().items, hasLength(3));
    });

    test('read all marks the loaded rows read and zeroes the badge', () async {
      await inbox().refresh();
      expect(await inbox().readAll(), isTrue);
      expect(state().items.every((m) => m.isRead), isTrue);
      expect(state().unreadCount, 0);
    });

    test('a failed read all changes nothing', () async {
      await inbox().refresh();
      api.failBulk = true;
      expect(await inbox().readAll(), isFalse);
      expect(state().unreadCount, 2);
      expect(state().items.where((m) => m.isRead), hasLength(1));
    });

    test('logout clears the inbox', () async {
      await inbox().refresh();
      SessionNotifier.instance.setAuthenticated(false);
      expect(state().items, isEmpty);
      expect(state().unreadCount, 0);
      expect(state().loaded, isFalse);
    });
  });

  group('InboxApi.delete', () {
    test('a 404 counts as deleted', () async {
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (o, h) => h.reject(
              DioException(
                requestOptions: o,
                response: Response(requestOptions: o, statusCode: 404),
              ),
            ),
          ),
        );
      await expectLater(InboxApi(dio).delete('gone'), completes);
    });

    test('other errors are thrown', () async {
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (o, h) => h.reject(
              DioException(
                requestOptions: o,
                response: Response(requestOptions: o, statusCode: 500),
              ),
            ),
          ),
        );
      await expectLater(
        InboxApi(dio).delete('x'),
        throwsA(isA<DioException>()),
      );
    });
  });

  group('InboxMessage', () {
    test('parses a backend row', () {
      final page = InboxPage.fromJson({
        'items': [
          {
            'id': '0b5e',
            'campaign_id': 'c1',
            'title': 'โบนัส',
            'body': 'วิ่งครบ 10 รอบ',
            'data': {'screen': 'incentives', 'deeplink': '/incentives'},
            'read_at': null,
            'created_at': '2026-10-30T03:24:00Z',
          },
        ],
        'unread_count': 4,
      });
      final m = page.items.single;
      expect(page.unreadCount, 4);
      expect(m.campaignId, 'c1');
      expect(m.isRead, isFalse);
      expect(m.createdAt.isUtc, isFalse);
      expect(m.link?.kind, InboxLinkKind.quests);
    });

    test('a null data map and a missing count are fine', () {
      final page = InboxPage.fromJson({
        'items': [
          {'id': 'x', 'title': 't', 'body': 'b', 'data': null},
        ],
      });
      expect(page.unreadCount, 0);
      expect(page.items.single.link, isNull);
    });

    test('links: https opens the web, home and http have no button', () {
      expect(
        _msg(
          'w',
          data: {'screen': 'url', 'url': 'https://mass.example/a'},
        ).link?.url,
        'https://mass.example/a',
      );
      expect(
        _msg('h', data: {'screen': 'home', 'deeplink': '/main'}).link,
        isNull,
      );
      expect(
        _msg('p', data: {'screen': 'url', 'url': 'http://x.test'}).link,
        isNull,
      );
    });
  });

  group('InboxStrings', () {
    final now = DateTime(2026, 10, 30, 12);

    test('groups by today, yesterday, then the Thai date', () {
      const s = InboxStrings.th;
      expect(s.day(DateTime(2026, 10, 30, 0, 5), now), 'วันนี้');
      expect(s.day(DateTime(2026, 10, 29, 23, 59), now), 'เมื่อวาน');
      expect(s.day(DateTime(2026, 10, 28, 9), now), '28 ต.ค. 2569');
    });

    test('English dates', () {
      expect(InboxStrings.en.day(DateTime(2026, 10, 28), now), '28 Oct 2026');
      expect(
        InboxStrings.en.stamp(DateTime(2026, 10, 30, 9, 5), now),
        'Today 09:05',
      );
    });
  });
}
