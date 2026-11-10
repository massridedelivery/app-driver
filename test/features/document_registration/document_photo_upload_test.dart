import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:massdrive/features/document_registration/data/sources/document_registration_api.dart';
import 'package:massdrive/features/document_registration/domain/document_photo.dart';
import 'package:massdrive/features/document_registration/domain/models/registration_status.dart';

/// A camera-like photo: noisy pixels compress badly, like a real 12 MP shot.
Uint8List _noisyPhoto(int w, int h, {bool png = false}) {
  final r = Random(1);
  final image = img.Image(width: w, height: h);
  for (final p in image) {
    p
      ..r = r.nextInt(256)
      ..g = r.nextInt(256)
      ..b = r.nextInt(256);
  }
  return png ? img.encodePng(image) : img.encodeJpg(image, quality: 95);
}

class _Reply {
  const _Reply(this.body, [this.status = 200]);
  final Object? body;
  final int status;
}

class _Adapter implements HttpClientAdapter {
  _Adapter(this.respond);
  final _Reply Function(RequestOptions) respond;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final reply = respond(options);
    return ResponseBody.fromString(
      jsonEncode(reply.body),
      reply.status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('shrinkDocumentPhoto', () {
    test(
      'a large photo comes back as a JPEG under the target, 2000 px max',
      () {
        final out = shrinkDocumentPhoto((
          source: _noisyPhoto(3000, 2250),
          maxBytes: docPhotoTargetBytes,
        ))!;
        expect(isJpeg(out), isTrue);
        expect(out.length, lessThanOrEqualTo(docPhotoTargetBytes));
        final back = img.decodeJpg(out)!;
        expect(
          max(back.width, back.height),
          lessThanOrEqualTo(docPhotoMaxSide),
        );
      },
    );

    test('a tight limit shrinks further', () {
      final out = shrinkDocumentPhoto((
        source: _noisyPhoto(1500, 1000),
        maxBytes: 150 * 1024,
      ))!;
      expect(out.length, lessThanOrEqualTo(150 * 1024));
    });

    test('something that is not an image is left alone', () {
      expect(
        shrinkDocumentPhoto((
          source: Uint8List.fromList([1, 2, 3]),
          maxBytes: 10,
        )),
        isNull,
      );
    });
  });

  group('upload', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync());

    ({DocumentRegistrationApi api, _Adapter server, _Adapter storage}) make({
      int? maxBytes,
      _Reply Function(RequestOptions)? confirm,
    }) {
      final server = _Adapter((o) {
        if (o.path.contains('upload-url')) {
          return _Reply({
            'upload_url':
                'https://storage.test/p/x.jpg?sig=0123456789012345678901234567890123456789',
            'file_key': 'driver_doc/drv-1/x.jpg',
            'max_bytes': ?maxBytes,
          });
        }
        if (o.path.contains('media/confirm')) {
          return confirm?.call(o) ?? const _Reply({'confirmed': true});
        }
        return const _Reply({
          'id': 'd1',
          'doc_type': 'vehicle_photo',
          'status': 'pending',
        });
      });
      final storage = _Adapter((_) => const _Reply({}));
      final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = server;
      final api = DocumentRegistrationApi(dio)
        ..newStorageDio = () => Dio()..httpClientAdapter = storage;
      return (api: api, server: server, storage: storage);
    }

    int putBytes(_Adapter storage) =>
        int.parse('${storage.requests.single.headers['Content-Length']}');

    test('a camera photo is shrunk before the PUT', () async {
      final photo = File('${dir.path}/car.jpg')
        ..writeAsBytesSync(_noisyPhoto(3000, 2250));
      expect(photo.lengthSync(), greaterThan(docPhotoTargetBytes));
      final t = make();

      await t.api.uploadDocument(photo, DocumentType.vehiclePhoto);

      expect(putBytes(t.storage), lessThanOrEqualTo(docPhotoTargetBytes));
      expect(t.storage.requests.single.contentType, 'image/jpeg');
    });

    test(
      'still over the max_bytes the upload URL allows → compressed again',
      () async {
        final photo = File('${dir.path}/car.jpg')
          ..writeAsBytesSync(_noisyPhoto(1200, 900));
        final t = make(maxBytes: 120 * 1024);

        await t.api.uploadDocument(photo, DocumentType.vehiclePhoto);

        expect(putBytes(t.storage), lessThanOrEqualTo(120 * 1024));
      },
    );

    test('a PNG becomes a JPEG and the URL is asked for image/jpeg', () async {
      final photo = File('${dir.path}/card.png')
        ..writeAsBytesSync(_noisyPhoto(600, 400, png: true));
      final t = make();

      await t.api.uploadDocument(photo, DocumentType.idCard);

      final ask = t.server.requests.firstWhere(
        (r) => r.path.contains('upload-url'),
      );
      expect(ask.queryParameters['content_type'], 'image/jpeg');
      expect(t.storage.requests.single.contentType, 'image/jpeg');
    });

    test(
      'confirm 422 file_too_large → the backend text, as a retake error',
      () async {
        final photo = File('${dir.path}/car.jpg')
          ..writeAsBytesSync(_noisyPhoto(300, 200));
        final t = make(
          confirm: (_) => const _Reply({
            'code': 'file_too_large',
            'error': 'ไฟล์ใหญ่เกิน 15 MB กรุณาถ่ายรูปใหม่',
          }, 422),
        );

        await expectLater(
          t.api.uploadDocument(photo, DocumentType.vehiclePhoto),
          throwsA(
            isA<DocumentFileTooLargeException>().having(
              (e) => e.message,
              'message',
              'ไฟล์ใหญ่เกิน 15 MB กรุณาถ่ายรูปใหม่',
            ),
          ),
        );
      },
    );
  });
}
