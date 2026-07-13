import 'dart:io';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:massdrive/core/constants/endpoints.dart';
import 'package:massdrive/core/constants/media_category.dart';
import 'package:massdrive/features/document_registration/domain/models/registration_status.dart';

@lazySingleton
class DocumentRegistrationApi {
  final Dio dio;

  DocumentRegistrationApi(this.dio);

  Future<List<dynamic>> fetchDocuments() async {
    final response = await dio.get(Endpoints.documentConfirm);
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

    final requestUrlResponse = await dio.get(
      Endpoints.documentUploadUrl,
      queryParameters: queryParams,
    );

    final uploadUrlData = requestUrlResponse.data as Map<String, dynamic>;
    final String uploadUrl = uploadUrlData['upload_url'] as String;
    final String fileKey = uploadUrlData['file_key'] as String;
    // max_bytes and expires_at are available if needed in future:
    // final int maxBytes = uploadUrlData['max_bytes'] as int? ?? category.maxSizeBytes;
    // final String expiresAt = uploadUrlData['expires_at'] as String? ?? '';


    // Step 2: Direct Binary Upload to presigned URL
    // Must use raw binary body — NO FormData.
    // Content-Type header must exactly match what was sent in Step 1.
    final storageDio = Dio(); // fresh Dio so no auth interceptors touch the storage request
    final fileBytes = await file.readAsBytes();

    await storageDio.put(
      uploadUrl,
      data: Stream.fromIterable([fileBytes]),
      options: Options(
        headers: {
          Headers.contentTypeHeader: contentType,
          Headers.contentLengthHeader: fileBytes.length.toString(),
        },
      ),
    );

    // Step 3: Server Confirmation — POST /api/media/confirm
    // Must be called after a successful PUT so the server marks the file as permanent.
    final confirmMediaResponse = await dio.post(
      Endpoints.mediaConfirm,
      data: {'file_key': fileKey},
    );
    final confirmData = confirmMediaResponse.data as Map<String, dynamic>;
    final bool confirmed = confirmData['confirmed'] as bool? ?? false;
    if (!confirmed) {
      throw Exception('Media confirmation failed for file_key: $fileKey');
    }

    // Step 4: Register Document with Driver Profile
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
}
