import 'dart:io';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:massdrive/core/constants/endpoints.dart';
import 'package:massdrive/features/document_registration/domain/models/registration_status.dart';

@lazySingleton
class DocumentRegistrationApi {
  final Dio dio;

  DocumentRegistrationApi(this.dio);

  Future<Map<String, dynamic>> uploadDocument(
    File file,
    DocumentType type, {
    String purpose = 'driver_document',
  }) async {
    // Determine content type based on file extension
    final ext = file.path.split('.').last.toLowerCase();
    String contentType = 'image/jpeg';
    if (ext == 'png') contentType = 'image/png';
    if (ext == 'pdf') contentType = 'application/pdf';

    // Map DocumentType to required API string format
    String documentTypeStr = '';
    switch (type) {
      case DocumentType.idCard:
        documentTypeStr = 'id_card';
        break;
      case DocumentType.drivingLicense:
        documentTypeStr = 'drivers_license';
        break;
      case DocumentType.vehicleRegistration:
        documentTypeStr = 'vehicle_registration';
        break;
      case DocumentType.insurance:
        documentTypeStr = 'insurance';
        break;
      case DocumentType.profilePhoto:
        documentTypeStr = 'profile_photo';
        break;
      case DocumentType.vehiclePhoto:
        documentTypeStr = 'vehicle_photo';
        break;
      case DocumentType.bankPassbook:
        documentTypeStr = 'bank_passbook';
        break;
    }

    final fileSize = await file.length();

    // Step 1: Request Presigned Upload URL
    final requestUrlResponse = await dio.post(
      Endpoints.documentUploadUrl,
      data: {
        "file_type": contentType,
        "file_size": fileSize,
        "purpose": purpose,
        "document_type": documentTypeStr,
      },
    );

    final uploadUrlData = requestUrlResponse.data;
    final String uploadUrl = uploadUrlData['upload_url'];
    final String fileKey = uploadUrlData['file_key'];

    // Step 2: Upload File Directly to Storage (R2)
    // Create a new Dio instance without interceptors so we don't send auth headers to R2
    final storageDio = Dio();

    // Read file bytes
    final fileBytes = await file.readAsBytes();

    await storageDio.put(
      uploadUrl,
      data: Stream.fromIterable([fileBytes]),
      options: Options(
        headers: {
          Headers.contentTypeHeader: contentType,
          Headers.contentLengthHeader: fileSize.toString(),
        },
      ),
    );

    // Step 3: Confirm Document Upload
    final confirmResponse = await dio.post(
      Endpoints.documentConfirm,
      data: {"document_type": documentTypeStr, "file_key": fileKey},
    );

    return confirmResponse.data as Map<String, dynamic>;
  }
}
