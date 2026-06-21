import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:massdrive/core/constants/endpoints.dart';
import 'package:massdrive/core/constants/media_category.dart';
import 'package:massdrive/features/document_registration/domain/models/registration_status.dart';
import 'package:massdrive/features/document_registration/domain/models/bank_account_info.dart';

@lazySingleton
class DocumentRegistrationApi {
  final Dio dio;

  DocumentRegistrationApi(this.dio);

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
    bool isUpdate = false,
    String? docTypeOverride,
  }) async {
    // Determine content type based on file extension
    final ext = file.path.split('.').last.toLowerCase();
    String contentType = 'image/jpeg';
    if (ext == 'png') contentType = 'image/png';
    if (ext == 'webp') contentType = 'image/webp';
    if (ext == 'pdf') contentType = 'application/pdf';

    // Validate MIME type is allowed for the given category
    if (!category.isMimeTypeAllowed(contentType)) {
      throw Exception(
        'File type "$contentType" is not allowed for category "${category.purpose}". '
        'Allowed types: ${category.allowedMimeTypes.join(", ")}',
      );
    }

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

    // Step 1: Request Presigned Upload URL
    // Query params per API spec: category, content_type (room_id only for chat)
    final queryParams = <String, dynamic>{
      'category': category.purpose,
      'content_type': contentType,
    };
    if (category == MediaCategory.chat) {
      // room_id must be supplied externally if needed; skip for driver docs
      queryParams['room_id'] = '';
    }

    debugPrint('[Upload] Step1: GET upload URL | category=${category.purpose} content_type=$contentType');
    final requestUrlResponse = await dio.get(
      Endpoints.documentUploadUrl,
      queryParameters: queryParams,
    );

    final uploadUrlData = requestUrlResponse.data as Map<String, dynamic>;
    final String uploadUrl = uploadUrlData['upload_url'] as String;
    final String fileKey = uploadUrlData['file_key'] as String;
    debugPrint('[Upload] Step1 OK | file_key=$fileKey upload_url=${uploadUrl.substring(0, 60)}...');
    // max_bytes and expires_at are available if needed in future:
    // final int maxBytes = uploadUrlData['max_bytes'] as int? ?? category.maxSizeBytes;
    // final String expiresAt = uploadUrlData['expires_at'] as String? ?? '';


    // Step 2: Direct Binary Upload to presigned URL
    // Must use raw binary body — NO FormData, NO Stream (MinIO rejects chunked encoding).
    // Content-Type header must exactly match what was sent in Step 1.
    final storageDio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 120),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
    final fileBytes = await file.readAsBytes();

    debugPrint('[Upload] Step2: PUT to MinIO | bytes=${fileBytes.length} content_type=$contentType');
    await storageDio.put(
      uploadUrl,
      data: fileBytes,
      options: Options(
        contentType: contentType,
        headers: {
          'Content-Length': fileBytes.length,
        },
      ),
    );
    debugPrint('[Upload] Step2 OK: Binary upload to MinIO succeeded');

    // Step 3: Server Confirmation — POST /api/media/confirm
    // Must be called after a successful PUT so the server marks the file as permanent.
    debugPrint('[Upload] Step3: POST media/confirm | file_key=$fileKey');
    final confirmMediaResponse = await dio.post(
      Endpoints.mediaConfirm,
      data: {'file_key': fileKey},
    );
    final confirmData = confirmMediaResponse.data as Map<String, dynamic>;
    final bool confirmed = confirmData['confirmed'] as bool? ?? false;
    debugPrint('[Upload] Step3 result: confirmed=$confirmed');
    if (!confirmed) {
      throw Exception('Media confirmation failed for file_key: $fileKey');
    }

    debugPrint('[Upload] Step4: Register doc | type=$documentTypeStr isUpdate=$isUpdate');
    Response confirmResponse;
    if (isUpdate) {
      // Correction / Update (Upsert)
      confirmResponse = await dio.put(
        '${Endpoints.documentConfirm}/$documentTypeStr',
        data: {
          "file_key": fileKey,
          "doc_number": docNumber ?? "",
        },
      );
    } else {
      // Initial Submission
      confirmResponse = await dio.post(
        Endpoints.documentConfirm,
        data: {
          "type": documentTypeStr,
          "file_key": fileKey,
          "doc_number": docNumber ?? "",
        },
      );
    }

    return confirmResponse.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> uploadBankPassbook(
    File file,
    BankAccountInfo info,
  ) async {
    // Determine content type based on file extension
    final ext = file.path.split('.').last.toLowerCase();
    String contentType = 'image/jpeg';
    if (ext == 'png') contentType = 'image/png';
    if (ext == 'webp') contentType = 'image/webp';
    if (ext == 'pdf') contentType = 'application/pdf';

    final category = MediaCategory.driverDoc;

    // Step 1: Request Presigned Upload URL
    final queryParams = <String, dynamic>{
      'category': category.purpose,
      'content_type': contentType,
    };

    debugPrint('[Upload Passbook] Step1: GET upload URL');
    final requestUrlResponse = await dio.get(
      Endpoints.documentUploadUrl,
      queryParameters: queryParams,
    );

    final uploadUrlData = requestUrlResponse.data as Map<String, dynamic>;
    final String uploadUrl = uploadUrlData['upload_url'] as String;
    final String fileKey = uploadUrlData['file_key'] as String;
    debugPrint('[Upload Passbook] Step1 OK | file_key=$fileKey');

    // Step 2: Direct Binary Upload to presigned URL
    final storageDio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 120),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
    final fileBytes = await file.readAsBytes();

    debugPrint('[Upload Passbook] Step2: PUT to MinIO');
    await storageDio.put(
      uploadUrl,
      data: fileBytes,
      options: Options(
        contentType: contentType,
        headers: {
          'Content-Length': fileBytes.length,
        },
      ),
    );
    debugPrint('[Upload Passbook] Step2 OK');

    // Step 3: Server Confirmation — POST /api/media/confirm
    debugPrint('[Upload Passbook] Step3: POST media/confirm | file_key=$fileKey');
    final confirmMediaResponse = await dio.post(
      Endpoints.mediaConfirm,
      data: {'file_key': fileKey},
    );
    final confirmData = confirmMediaResponse.data as Map<String, dynamic>;
    final bool confirmed = confirmData['confirmed'] as bool? ?? false;
    if (!confirmed) {
      throw Exception('Media confirmation failed for file_key: $fileKey');
    }
    debugPrint('[Upload Passbook] Step3 OK');

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
}
