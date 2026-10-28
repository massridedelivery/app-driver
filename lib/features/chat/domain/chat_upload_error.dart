import 'package:dio/dio.dart';

/// Why a chat image didn't go through, in Thai, and what to do next.
class ChatUploadFailure {
  const ChatUploadFailure(
    this.message, {
    required this.retryable,
    this.reupload = false,
  });

  final String message;

  /// A connection problem: keep it queued and retry on its own.
  final bool retryable;

  /// The file was refused (400): the next try must upload it again rather
  /// than re-send the old file_key.
  final bool reupload;
}

const chatBlockedMessage = 'ส่งรูปไม่ได้ เนื่องจากถูกบล็อก';
const chatInvalidFileMessage =
    'ไฟล์รูปไม่ถูกต้องหรือใหญ่เกินไป อัปโหลดไม่สำเร็จ กรุณาอัปโหลดใหม่';
const chatOfflineMessage = 'รอสัญญาณอินเทอร์เน็ต จะส่งให้อัตโนมัติ';
const chatSendFailedMessage = 'ส่งรูปไม่สำเร็จ แตะเพื่อลองใหม่';

/// Maps an upload/send error to a [ChatUploadFailure]:
/// 403 blocked · 400 bad file (upload again) · no response / timeout / 5xx →
/// wait and retry automatically.
ChatUploadFailure classifyChatUploadError(Object error) {
  if (error is ChatUploadRefused) {
    return const ChatUploadFailure(
      chatInvalidFileMessage,
      retryable: false,
      reupload: true,
    );
  }
  if (error is DioException) {
    final code = error.response?.statusCode;
    if (code == 403) {
      return const ChatUploadFailure(chatBlockedMessage, retryable: false);
    }
    if (code == 400 || code == 413 || code == 415) {
      return const ChatUploadFailure(
        chatInvalidFileMessage,
        retryable: false,
        reupload: true,
      );
    }
    if (code == null || code >= 500 || code == 408 || code == 429) {
      return const ChatUploadFailure(chatOfflineMessage, retryable: true);
    }
  }
  return const ChatUploadFailure(chatSendFailedMessage, retryable: false);
}

/// The backend didn't confirm the uploaded file.
class ChatUploadRefused implements Exception {
  const ChatUploadRefused();
}
