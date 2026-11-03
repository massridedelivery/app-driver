import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/features/document_registration/domain/models/profile_photo_error.dart';

DioException _status(int code, [Object? data]) {
  final request = RequestOptions(path: '/api/driver/documents');
  return DioException(
    requestOptions: request,
    type: DioExceptionType.badResponse,
    response: Response(requestOptions: request, statusCode: code, data: data),
  );
}

void main() {
  // The backend answers 400 for a "selfie" that isn't a JPEG/PNG/WebP, with an
  // English reason. The driver should be told to pick another photo.
  test('a 400 from the backend asks for another photo', () {
    expect(
      profilePhotoUploadError(_status(400, {'error': 'selfie is not an image: image/heic'})),
      notAnImageMessage,
    );
  });

  test("a type the upload refuses up front asks for another photo", () {
    expect(
      profilePhotoUploadError(Exception(
        'File type "application/octet-stream" is not allowed for category "driver_doc". '
        'Allowed types: image/jpeg, image/png, application/pdf',
      )),
      notAnImageMessage,
    );
  });

  test('other failures keep the usual message', () {
    expect(profilePhotoUploadError(_status(503)), isNot(notAnImageMessage));
    expect(
      profilePhotoUploadError(
        DioException(
          requestOptions: RequestOptions(path: '/'),
          type: DioExceptionType.connectionError,
        ),
      ),
      'เชื่อมต่ออินเทอร์เน็ตไม่ได้ กรุณาตรวจสอบสัญญาณแล้วลองใหม่',
    );
  });
}
