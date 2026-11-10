import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:massdrive/core/constants/endpoints.dart';
import 'package:massdrive/core/constants/media_category.dart';
import 'package:massdrive/core/data/sources/api_error.dart';
import 'package:massdrive/features/document_registration/domain/document_photo.dart';
import 'package:massdrive/features/document_registration/domain/models/registration_status.dart';
import 'package:massdrive/features/document_registration/domain/models/bank_account_info.dart';

@lazySingleton
class DocumentRegistrationApi {
  final Dio dio;

  DocumentRegistrationApi(this.dio);

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

  /// Steps 1–3 of a media upload: presigned URL, PUT, confirm. Returns the
  /// confirmed `file_key`.
  ///
  /// A photo is shrunk first ([docPhotoTargetBytes]) so it goes up quickly on
  /// mobile data, and again if it is still over the `max_bytes` the upload URL
  /// allows — compressing before the PUT instead of failing at confirm. A
  /// confirm 422 `file_too_large` becomes [DocumentFileTooLargeException]
  /// with the backend's text.
  Future<String> _uploadMedia(
    File file,
    MediaCategory category, {
    required String tag,
  }) async {
    final ext = file.path.split('.').last.toLowerCase();
    var contentType = switch (ext) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'pdf' => 'application/pdf',
      _ => 'image/jpeg',
    };
    var bytes = await file.readAsBytes();
    final isPhoto = contentType != 'application/pdf';

    Future<bool> shrinkTo(int maxBytes) async {
      final out = await compute(shrinkDocumentPhoto, (
        source: bytes,
        maxBytes: maxBytes,
      ));
      if (out == null) return false; // not a readable image: send as is
      debugPrint('[$tag] photo ${bytes.length} → ${out.length} bytes');
      bytes = out;
      contentType = 'image/jpeg';
      return true;
    }

    if (isPhoto && (bytes.length > docPhotoTargetBytes || !isJpeg(bytes))) {
      await shrinkTo(docPhotoTargetBytes);
    }

    if (!category.isMimeTypeAllowed(contentType)) {
      throw Exception(
        'File type "$contentType" is not allowed for category "${category.purpose}". '
        'Allowed types: ${category.allowedMimeTypes.join(", ")}',
      );
    }

    // Step 1: presigned upload URL for this content type (room_id is for
    // chat only). Its max_bytes is the size the backend will confirm.
    Future<Map<String, dynamic>> requestUrl() async {
      debugPrint('[$tag] Step1: GET upload URL | category=${category.purpose} content_type=$contentType');
      final response = await dio.get(
        Endpoints.documentUploadUrl,
        queryParameters: {
          'category': category.purpose,
          'content_type': contentType,
          if (category == MediaCategory.chat) 'room_id': '',
        },
      );
      return response.data as Map<String, dynamic>;
    }

    var urlData = await requestUrl();
    final maxBytes = (urlData['max_bytes'] as num?)?.toInt();
    if (isPhoto && maxBytes != null && bytes.length > maxBytes) {
      final wasJpeg = contentType == 'image/jpeg';
      if (await shrinkTo(maxBytes) && !wasJpeg) {
        // The URL was signed for the old content type.
        urlData = await requestUrl();
      }
    }
    final uploadUrl = urlData['upload_url'] as String;
    final fileKey = urlData['file_key'] as String;

    // Step 2: raw binary PUT — no FormData, no stream (MinIO rejects chunked
    // encoding); Content-Type must match step 1.
    debugPrint('[$tag] Step2: PUT | bytes=${bytes.length} content_type=$contentType');
    await newStorageDio().put(
      uploadUrl,
      data: bytes,
      options: Options(
        contentType: contentType,
        headers: {'Content-Length': bytes.length},
      ),
    );

    // Step 3: POST /api/media/confirm makes the file permanent.
    debugPrint('[$tag] Step3: POST media/confirm | file_key=$fileKey');
    final Response<dynamic> confirm;
    try {
      confirm = await dio.post(
        Endpoints.mediaConfirm,
        data: {'file_key': fileKey},
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      if (e.response?.statusCode == 422 &&
          data is Map &&
          data['code'] == 'file_too_large') {
        throw DocumentFileTooLargeException(
          ApiError.serverMessage(e) ??
              'ไฟล์มีขนาดใหญ่เกินไป กรุณาถ่ายรูปใหม่อีกครั้ง',
        );
      }
      rethrow;
    }
    final confirmed =
        (confirm.data as Map<String, dynamic>)['confirmed'] as bool? ?? false;
    if (!confirmed) {
      throw Exception('Media confirmation failed for file_key: $fileKey');
    }
    return fileKey;
  }

  Future<List<dynamic>> fetchDocuments() async {
    final response = await dio.get(Endpoints.documentConfirm);
    try {
      final list = response.data as List<dynamic>;
      debugPrint('=== DEBUG /api/driver/documents RAW RESPONSE ===');
      debugPrint(list.toString());
      debugPrint('=== UNAPPROVED DOCUMENTS ===');
      bool hasUnapproved = false;
      for (final doc in list) {
        if (doc is Map<String, dynamic>) {
          final status = doc['status'] as String? ?? '';
          if (status != 'approved') {
            hasUnapproved = true;
            debugPrint('Doc Type: ${doc['doc_type']} | Status: $status | Reason: ${doc['rejection_reason']}');
          }
        }
      }
      if (!hasUnapproved) {
        debugPrint('All documents are approved!');
      }
      debugPrint('================================================');
    } catch (e) {
      debugPrint('Error debugging documents: $e');
    }
    return response.data as List<dynamic>;
  }

  Future<String> getTemporaryViewUrl(String fileKey) async {
    final response = await dio.get(
      Endpoints.mediaView,
      queryParameters: {'key': fileKey},
    );
    return response.data['view_url'] as String? ?? '';
  }

  Future<Map<String, dynamic>> uploadDocument(
    File file,
    DocumentType type, {
    MediaCategory category = MediaCategory.driverDoc,
    String? docNumber,
    String? docTypeOverride,
  }) async {
    // Map DocumentType to required API string format
    String documentTypeStr = docTypeOverride ?? '';
    if (documentTypeStr.isEmpty) {
      switch (type) {
        case DocumentType.idCard:
          documentTypeStr = 'id_card';
          break;
        case DocumentType.drivingLicense:
          documentTypeStr = 'driver_license';
          break;
        case DocumentType.publicDrivingLicense:
          documentTypeStr = 'public_transport_license';
          break;
        case DocumentType.vehicleRegistration:
          documentTypeStr = 'vehicle_registration';
          break;
        case DocumentType.insurance:
          documentTypeStr = 'insurance';
          break;
        case DocumentType.profilePhoto:
          documentTypeStr = 'selfie';
          break;
        case DocumentType.vehiclePhoto:
          documentTypeStr = 'vehicle_photo';
          break;
        case DocumentType.bankPassbook:
          documentTypeStr = 'bank_passbook';
          break;
      }
    }

    final fileKey = await _uploadMedia(file, category, tag: 'Upload');

    // Step 4: Register the document — POST /api/driver/documents, for a first
    // upload and a re-upload alike. The backend replaces the driver's document
    // of that type (ReplaceDocument); there is no PUT /documents/:type, and
    // calling one failed every re-upload with "Cannot PUT …" (404).
    debugPrint('[Upload] Step4: POST documents | type=$documentTypeStr');
    final confirmResponse = await dio.post(
      Endpoints.documentConfirm,
      data: {
        "type": documentTypeStr,
        "file_key": fileKey,
        "doc_number": docNumber ?? "",
      },
    );

    return confirmResponse.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> uploadBankPassbook(
    File file,
    BankAccountInfo info,
  ) async {
    final fileKey = await _uploadMedia(
      file,
      MediaCategory.driverDoc,
      tag: 'Upload Passbook',
    );

    // Step 4: Update Payout Method — PUT /api/driver/payouts/method
    debugPrint('[Upload Passbook] Step4: PUT payouts/method | file_key=$fileKey');
    final payoutResponse = await dio.put(
      Endpoints.driverPayoutsMethod,
      data: {
        "method": {
          "type": "bank_transfer",
          "details": {
            "bank_name": info.bankName,
            "account_number": info.accountNumber,
            "account_name": info.accountName,
          }
        },
        "file_key": fileKey,
      },
    );

    return payoutResponse.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updatePayoutMethod(
    BankAccountInfo info,
    String fileKey,
  ) async {
    final payoutResponse = await dio.put(
      Endpoints.driverPayoutsMethod,
      data: {
        "method": {
          "type": "bank_transfer",
          "details": {
            "bank_name": info.bankName,
            "account_number": info.accountNumber,
            "account_name": info.accountName,
          }
        },
        "file_key": fileKey,
      },
    );
    return payoutResponse.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>?> fetchPayoutMethod() async {
    try {
      final response = await dio.get(Endpoints.driverPayoutsMethod);
      return response.data as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('Error fetching payout method: $e');
      return null;
    }
  }

  /// Final registration submit (SCRUM-75). The driver token identifies the
  /// driver; [body] carries the accepted consents.
  Future<void> submitRegistration(Map<String, dynamic> body) async {
    await dio.post(Endpoints.registrationSubmit, data: body);
  }
}
