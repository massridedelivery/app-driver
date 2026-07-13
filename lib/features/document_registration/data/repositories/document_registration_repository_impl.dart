import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:massdrive/core/constants/media_category.dart';
import '../../domain/models/bank_account_info.dart';
import '../../domain/models/driver_profile_info.dart';
import '../../domain/models/registration_status.dart';
import '../../domain/models/vehicle_info.dart';
import '../../domain/models/driver_document_model.dart';
import '../../domain/repositories/document_registration_repository.dart';
import '../sources/document_registration_api.dart';
import '../../../profile/data/sources/profile_api_service.dart';

@LazySingleton(as: DocumentRegistrationRepository)
class DocumentRegistrationRepositoryImpl
    implements DocumentRegistrationRepository {
  final DocumentRegistrationApi _api;
  final ProfileApiService _profileApi;

  DocumentRegistrationRepositoryImpl(this._api, this._profileApi);

  @override
  Future<void> updateProfile(DriverProfileInfo info) async {
    await _profileApi.updateProfile({
      "full_name": "${info.firstName} ${info.lastName}",
      "email": info.email,
      "emergency_contact": info.emergencyContact
    });
  }

  @override
  Future<String> uploadDocument(
    File file,
    DocumentType type, {
    MediaCategory category = MediaCategory.driverDoc,
    String? docNumber,
    bool isUpdate = false,
    String? docTypeOverride,
  }) async {
    final response = await _api.uploadDocument(
      file,
      type,
      category: category,
      docNumber: docNumber,
      isUpdate: isUpdate,
      docTypeOverride: docTypeOverride,
    );
    return response['image_url'] as String? ?? response['media_url'] as String? ?? '';
  }

  @override
  Future<List<DriverDocumentModel>> fetchDocuments() async {
    final list = await _api.fetchDocuments();
    return list.map((e) => DriverDocumentModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<String> getTemporaryViewUrl(String fileKey) async {
    return await _api.getTemporaryViewUrl(fileKey);
  }

  @override
  Future<void> submitVehicleDetails(VehicleInfo info) async {
    await _profileApi.updateProfile({
      "vehicle_plate": info.licensePlate,
      "vehicle_model": info.model,
      "vehicle_year": info.year,
    });
  }

  @override
  Future<void> submitBankDetails(BankAccountInfo info) async {
    // Currently no API specifically defined in driver_integration.md for submitting Bank Details only
    // This could also be an updateProfile
    print("MOCK Action: submitBankDetails for ${info.accountName}");
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<void> submitFinalConsent(
    String driverId,
    bool criminalCheckConsent,
  ) async {
     // No specific final consent API listed, potentially mapped to updateProfile later
    print("MOCK Action: submitFinalConsent for $driverId");
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<RegistrationStatusInfo> fetchRegistrationStatus() async {
    final response = await _profileApi.getProfile();
    final data = response.data!;
    // is_verified from /api/driver/profile is the single source of truth.
    // Only return approved when the backend explicitly confirms it.
    final bool isVerified = data['verified'] ?? false;

    if (isVerified) {
      return RegistrationStatusInfo(
        status: RegistrationStateStatus.approved,
        rejectedReasons: [],
        missingDocuments: [],
      );
    }

    // is_verified = false → driver must go through the checklist.
    // Inspect document statuses only to pick the correct sub-state
    // so the checklist screen can render the right view (rejected / inReview / pending).
    try {
      final docList = await fetchDocuments();

      final rejectedDocs = docList.where((d) => d.status == 'rejected').toList();
      if (rejectedDocs.isNotEmpty) {
        final reasons = rejectedDocs
            .map((d) => '${d.docType}: ${d.rejectionReason ?? "Rejected"}')
            .toList();
        return RegistrationStatusInfo(
          status: RegistrationStateStatus.rejected,
          rejectedReasons: reasons,
          missingDocuments: [],
        );
      }

      final hasPending = docList.any((d) => d.status == 'pending');
      if (hasPending) {
        return RegistrationStatusInfo(
          status: RegistrationStateStatus.inReview,
          rejectedReasons: [],
          missingDocuments: [],
        );
      }

      // Docs uploaded but none are pending/rejected — waiting for admin action.
      if (docList.isNotEmpty) {
        return RegistrationStatusInfo(
          status: RegistrationStateStatus.inReview,
          rejectedReasons: [],
          missingDocuments: [],
        );
      }
    } catch (e) {
      debugPrint('Error fetching documents status: $e');
    }

    // No documents uploaded yet.
    return RegistrationStatusInfo(
      status: RegistrationStateStatus.pending,
      rejectedReasons: [],
      missingDocuments: [],
    );
  }
}
