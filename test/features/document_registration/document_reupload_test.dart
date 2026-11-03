import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/features/document_registration/data/sources/document_registration_api.dart';
import 'package:massdrive/features/document_registration/domain/models/registration_status.dart';

/// Answers every request with [respond] and remembers what was sent.
class _RecordingAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  final Object? Function(RequestOptions) respond;

  _RecordingAdapter(this.respond);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode(respond(options)),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late File photo;

  setUp(() async {
    photo = File('${Directory.systemTemp.createTempSync().path}/face.jpg');
    await photo.writeAsBytes([1, 2, 3]);
  });

  // The backend has POST /api/driver/documents (replace by type) and no PUT
  // /api/driver/documents/:type. Changing the profile photo — a selfie the
  // driver already has — used to PUT and fail with "Cannot PUT …".
  test('a document upload registers through POST /api/driver/documents', () async {
    final api = _RecordingAdapter((o) {
      if (o.path.contains('upload-url')) {
        return {
          'upload_url': 'https://storage.test/presigned/face.jpg?sig=0123456789012345678901234567890123456789',
          'file_key': 'driver_doc/drv-1/face.jpg',
        };
      }
      if (o.path.contains('media/confirm')) return {'confirmed': true};
      return {'image_url': 'driver_doc/drv-1/face.jpg'};
    });
    final storage = _RecordingAdapter((_) => {});
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))..httpClientAdapter = api;
    final docs = DocumentRegistrationApi(dio)
      ..newStorageDio = () => Dio()..httpClientAdapter = storage;

    await docs.uploadDocument(photo, DocumentType.profilePhoto);

    final register = api.requests.last;
    expect(register.method, 'POST');
    expect(register.path, '/api/driver/documents');
    expect(register.data, {
      'type': 'selfie',
      'file_key': 'driver_doc/drv-1/face.jpg',
      'doc_number': '',
    });
    expect(api.requests.where((r) => r.method == 'PUT'), isEmpty);
    expect(storage.requests.single.method, 'PUT');
  });
}
