import 'package:dio/dio.dart';
import 'package:massdrive/core/utils/friendly_error.dart';

/// Shown when the picked profile photo isn't a JPEG, PNG or WebP.
const notAnImageMessage =
    'ไฟล์นี้ไม่ใช่รูปภาพ กรุณาเลือกรูปใหม่ (JPEG, PNG หรือ WebP)';

/// The message for a failed profile-photo (selfie) upload. The backend answers
/// 400 when the file isn't an image it can show, and the upload refuses a
/// type it can't send before that (both in English) — the driver needs "pick
/// another photo", not the raw reason.
String profilePhotoUploadError(Object error) {
  if (error is DioException && error.response?.statusCode == 400) {
    return notAnImageMessage;
  }
  if (error.toString().contains('is not allowed for category')) {
    return notAnImageMessage;
  }
  return friendlyErrorMessage(error);
}
