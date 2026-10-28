import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:massdrive/features/chat/data/chat_image_outbox.dart';
import 'package:massdrive/features/chat/data/sources/chat_api_service.dart';
import 'package:massdrive/features/chat/domain/chat_image_processing.dart';
import 'package:massdrive/features/chat/domain/chat_push_target.dart';
import 'package:massdrive/features/chat/domain/chat_upload_error.dart';
import 'package:massdrive/features/chat/domain/entities/chat_message.dart';
import 'package:massdrive/features/chat/domain/entities/chat_vertical.dart';

DioException _http(int code) => DioException(
  requestOptions: RequestOptions(path: '/x'),
  response: Response(
    requestOptions: RequestOptions(path: '/x'),
    statusCode: code,
  ),
  type: DioExceptionType.badResponse,
);

final _offline = DioException(
  requestOptions: RequestOptions(path: '/x'),
  type: DioExceptionType.connectionError,
);

/// Records calls; each step can be told to fail.
class _FakeApi implements ChatApiService {
  final calls = <String>[];
  Object? presignError, putError, sendError;
  bool confirmed = true;
  String? presignRoom;
  Map<String, dynamic>? sentBody;
  int keySeq = 0;

  @override
  Future<Response<Map<String, dynamic>>> getPresignedUploadUrl({
    required String contentType,
    required String id,
    required ChatVertical vertical,
  }) async {
    calls.add('presign');
    presignRoom = id;
    if (presignError != null) throw presignError!;
    return Response(
      requestOptions: RequestOptions(path: '/u'),
      data: {
        'upload_url': 'https://s3/put',
        'file_key': 'chat/k${keySeq++}.jpg',
      },
    );
  }

  @override
  Future<void> uploadFileToPresignedUrl({
    required String uploadUrl,
    required List<int> fileBytes,
    required String contentType,
    ProgressCallback? onSendProgress,
  }) async {
    calls.add('put:$contentType');
    if (putError != null) throw putError!;
    onSendProgress?.call(fileBytes.length ~/ 2, fileBytes.length);
    onSendProgress?.call(fileBytes.length, fileBytes.length);
  }

  @override
  Future<Response<Map<String, dynamic>>> confirmMediaUpload(
    String fileKey,
  ) async {
    calls.add('confirm:$fileKey');
    return Response(
      requestOptions: RequestOptions(path: '/c'),
      data: {'confirmed': confirmed},
    );
  }

  @override
  Future<Response<Map<String, dynamic>>> sendMessageRest({
    required String id,
    required ChatVertical vertical,
    required String msgType,
    required String text,
    String? fileKey,
  }) async {
    calls.add('send:$fileKey');
    sentBody = {'msg_type': msgType, 'text': text, 'file_key': fileKey};
    if (sendError != null) throw sendError!;
    return Response(
      requestOptions: RequestOptions(path: '/s'),
      statusCode: 201,
      data: {
        'message': 'sent',
        'data': {'id': 'msg-1'},
      },
    );
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  group('prepareChatImage', () {
    Uint8List photo({required int w, required int h, int orientation = 1}) {
      final image = img.Image(width: w, height: h);
      img.fill(image, color: img.ColorRgb8(200, 120, 40));
      image.exif.imageIfd.orientation = orientation;
      image.exif.gpsIfd['GPSLatitude'] = img.IfdValueRational(13, 1);
      return img.encodeJpg(image, quality: 95);
    }

    test('long side capped at 1600, JPEG, no EXIF, under 2 MB', () {
      final out = prepareChatImage(photo(w: 4000, h: 3000));
      final back = img.decodeJpg(out)!;
      expect(back.width, 1600);
      expect(back.height, 1200);
      expect(back.exif.isEmpty, isTrue, reason: 'GPS/EXIF must be stripped');
      expect(out.length, lessThan(chatImageMaxBytes));
    });

    test('camera rotation is applied to the pixels before EXIF goes', () {
      // Portrait shot stored landscape with orientation 6 (rotate 90°).
      final back = img.decodeJpg(
        prepareChatImage(photo(w: 2000, h: 1000, orientation: 6)),
      )!;
      // Turned upright (portrait), then capped at 1600 on the long side.
      expect(back.width, 800);
      expect(back.height, 1600);
      expect(back.exif.isEmpty, isTrue);
    });

    test('small photos keep their size', () {
      final back = img.decodeJpg(prepareChatImage(photo(w: 800, h: 600)))!;
      expect((back.width, back.height), (800, 600));
    });

    test('not an image → ChatImageDecodeException', () {
      expect(
        () => prepareChatImage(Uint8List.fromList([1, 2, 3])),
        throwsA(isA<ChatImageDecodeException>()),
      );
    });
  });

  group('classifyChatUploadError', () {
    test('403 blocked, 400 bad file (upload again), offline/5xx retry', () {
      expect(classifyChatUploadError(_http(403)).message, chatBlockedMessage);
      expect(classifyChatUploadError(_http(403)).retryable, isFalse);
      final bad = classifyChatUploadError(_http(400));
      expect(
        (bad.message, bad.retryable, bad.reupload),
        (chatInvalidFileMessage, false, true),
      );
      expect(classifyChatUploadError(_offline).retryable, isTrue);
      expect(classifyChatUploadError(_http(503)).retryable, isTrue);
      expect(
        classifyChatUploadError(const ChatUploadRefused()).reupload,
        isTrue,
      );
    });
  });

  group('ChatImageOutbox', () {
    late _FakeApi api;
    late StreamController<Object?> conn;
    late ChatImageOutbox outbox;

    setUp(() {
      api = _FakeApi();
      conn = StreamController<Object?>.broadcast();
      outbox = ChatImageOutbox(
        api: api,
        connectivityChanges: conn.stream,
        retryDelay: (_) => const Duration(hours: 1),
      );
    });
    tearDown(() async {
      await outbox.dispose();
      await conn.close();
    });

    final jpeg = Uint8List.fromList(List.filled(1000, 7));

    test('upload → confirm → send image with caption; bare room id', () async {
      final item = outbox.enqueue(
        id: 'JOB-9',
        vertical: ChatVertical.ride,
        bytes: jpeg,
        caption: 'จุดรับหน้าเซเว่น',
      );
      expect(outbox.itemsFor('job:JOB-9'), [item]);
      await _settle();
      expect(api.calls, [
        'presign',
        'put:image/jpeg',
        'confirm:chat/k0.jpg',
        'send:chat/k0.jpg',
      ]);
      expect(api.presignRoom, 'JOB-9');
      expect(api.sentBody, {
        'msg_type': 'image',
        'text': 'จุดรับหน้าเซเว่น',
        'file_key': 'chat/k0.jpg',
      });
      expect(item.status, OutboxStatus.sent);
      expect(item.serverId, 'msg-1');
      expect(item.progress, 1);
    });

    test('blocked (403): failed with the Thai reason, no auto retry', () async {
      api.sendError = _http(403);
      final item = outbox.enqueue(
        id: 'J',
        vertical: ChatVertical.food,
        bytes: jpeg,
      );
      await _settle();
      expect(item.status, OutboxStatus.failed);
      expect(item.message, chatBlockedMessage);
    });

    test('offline: waits, then goes when the connection is back', () async {
      api.presignError = _offline;
      final item = outbox.enqueue(
        id: 'J',
        vertical: ChatVertical.messenger,
        bytes: jpeg,
      );
      await _settle();
      expect(item.status, OutboxStatus.waiting);
      expect(item.message, chatOfflineMessage);

      api.presignError = null;
      conn.add(const ['wifi']);
      await _settle();
      expect(item.status, OutboxStatus.sent);
    });

    test(
      'send refused (400) after upload: retry uploads the file again',
      () async {
        api.sendError = _http(400);
        final item = outbox.enqueue(
          id: 'J',
          vertical: ChatVertical.ride,
          bytes: jpeg,
        );
        await _settle();
        expect(item.status, OutboxStatus.failed);
        expect(item.message, chatInvalidFileMessage);
        expect(item.fileKey, isNull);

        api.sendError = null;
        api.calls.clear();
        outbox.retry(item.localId);
        await _settle();
        expect(api.calls.first, 'presign');
        expect(item.status, OutboxStatus.sent);
        expect(item.fileKey, 'chat/k1.jpg');
      },
    );

    test(
      'network drop on send: retry only re-sends the stored file_key',
      () async {
        api.sendError = _offline;
        final item = outbox.enqueue(
          id: 'J',
          vertical: ChatVertical.ride,
          bytes: jpeg,
        );
        await _settle();
        expect(item.status, OutboxStatus.waiting);
        api.sendError = null;
        api.calls.clear();
        outbox.retry(item.localId);
        await _settle();
        expect(api.calls, ['send:chat/k0.jpg']);
      },
    );

    test('unconfirmed upload counts as a bad file', () async {
      api.confirmed = false;
      final item = outbox.enqueue(
        id: 'J',
        vertical: ChatVertical.ride,
        bytes: jpeg,
      );
      await _settle();
      expect(item.status, OutboxStatus.failed);
      expect(item.message, chatInvalidFileMessage);
    });

    test('discarding removes it from the room', () async {
      api.presignError = _offline;
      final item = outbox.enqueue(
        id: 'J',
        vertical: ChatVertical.ride,
        bytes: jpeg,
      );
      await _settle();
      outbox.remove(item.localId);
      expect(outbox.itemsFor('job:J'), isEmpty);
    });
  });

  group('chat push', () {
    test('room_id with a prefix picks the vertical', () {
      expect(
        chatTargetFromPush({'type': 'chat_message', 'room_id': 'job:J1'}),
        const ChatPushTarget(ChatVertical.ride, 'J1'),
      );
      expect(
        chatTargetFromPush({'type': 'chat_image', 'room_id': 'order:O1'}),
        const ChatPushTarget(ChatVertical.food, 'O1'),
      );
      expect(
        chatTargetFromPush({'msg_type': 'image', 'room_id': 'messenger:M1'}),
        const ChatPushTarget(ChatVertical.messenger, 'M1'),
      );
    });

    test('bare room_id uses service, else ride', () {
      expect(
        chatTargetFromPush({
          'type': 'chat',
          'room_id': 'O2',
          'service': 'food',
        }),
        const ChatPushTarget(ChatVertical.food, 'O2'),
      );
      expect(
        chatTargetFromPush({'type': 'chat', 'room_id': 'J2'}),
        const ChatPushTarget(ChatVertical.ride, 'J2'),
      );
    });

    test('other pushes are not chats', () {
      expect(
        chatTargetFromPush({'type': 'job_offer', 'room_id': 'job:J'}),
        isNull,
      );
      expect(chatTargetFromPush({'type': 'chat_message'}), isNull);
      expect(
        chatTargetFromPush({'type': 'chat', 'room_id': 'weird:J'}),
        isNull,
      );
    });

    test('local-notification payload round-trips', () {
      const t = ChatPushTarget(ChatVertical.messenger, 'M9');
      expect(ChatPushTarget.fromPayload(t.payload), t);
      expect(ChatPushTarget.fromPayload('/held-fares'), isNull);
    });
  });

  test('image message keeps its file_key', () {
    final m = ChatMessage.fromJson({
      'id': 'm1',
      'room_id': 'job:J',
      'sender_role': 'customer',
      'msg_type': 'image',
      'media_url': 'https://s3/x?sig',
      'file_key': 'chat/a.jpg',
      'text': 'ตรงนี้ค่ะ',
      'created_at': '2026-10-28T03:00:00Z',
    });
    expect(
      (m.msgType, m.fileKey, m.content),
      ('image', 'chat/a.jpg', 'ตรงนี้ค่ะ'),
    );
  });

  test('upload-url asks with the bare id as room_id', () async {
    final dio = Dio();
    Map<String, dynamic>? query;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (o, h) {
          query = o.queryParameters;
          h.resolve(Response(requestOptions: o, data: <String, dynamic>{}));
        },
      ),
    );
    await ChatApiServiceImpl(dio).getPresignedUploadUrl(
      contentType: 'image/jpeg',
      id: 'ORDER-1',
      vertical: ChatVertical.food,
    );
    expect(query, {
      'category': 'chat',
      'content_type': 'image/jpeg',
      'room_id': 'ORDER-1',
    });
  });
}
