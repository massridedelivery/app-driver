import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:massdrive/core/constants/endpoints.dart';
import 'package:massdrive/core/constants/media_category.dart';

/// Uploads a profile photo to the public `avatar` category and returns its
/// file_key, for `PUT /api/driver/profile {"avatar_url": <file_key>}`.
///
/// The profile photo is not the sign-up selfie: that is a verification
/// document (POST /api/driver/documents, type selfie) an admin reviews and
/// keeps on record. Changing the photo goes through here and needs no review.
class ProfilePhotoUploader {
  ProfilePhotoUploader(this._dio);

  final Dio _dio;

  /// The client for the presigned storage PUT (no auth, no base URL). Tests
  /// swap it to keep the upload off the network.
  @visibleForTesting
  Dio Function() newStorageDio = () => Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 120),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

  /// [jpeg] is already prepared (see `prepareChatImage`): JPEG, no EXIF, and
  /// within the avatar category's 2 MB.
  Future<String> upload(Uint8List jpeg) async {
    const contentType = 'image/jpeg';
    final minted = await _dio.get<Map<String, dynamic>>(
      Endpoints.documentUploadUrl,
      queryParameters: {
        'category': MediaCategory.avatar.purpose,
        'content_type': contentType,
      },
    );
    final uploadUrl = minted.data?['upload_url'] as String?;
    final fileKey = minted.data?['file_key'] as String?;
    if (uploadUrl == null || fileKey == null) {
      throw Exception('อัปโหลดรูปไม่สำเร็จ กรุณาลองใหม่อีกครั้ง');
    }

    // Raw bytes as the body, with the type the URL was minted for.
    await newStorageDio().put(
      uploadUrl,
      data: Stream.fromIterable([jpeg]),
      options: Options(
        contentType: contentType,
        headers: {'Content-Length': jpeg.length},
      ),
    );

    final confirmed = await _dio.post<Map<String, dynamic>>(
      Endpoints.mediaConfirm,
      data: {'file_key': fileKey},
    );
    if (confirmed.data?['confirmed'] != true) {
      throw Exception('อัปโหลดรูปไม่สำเร็จ กรุณาลองใหม่อีกครั้ง');
    }
    return fileKey;
  }
}
