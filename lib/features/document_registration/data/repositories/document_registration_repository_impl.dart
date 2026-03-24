import 'dart:io';
import 'package:injectable/injectable.dart';
import '../../domain/models/bank_account_info.dart';
import '../../domain/models/driver_profile_info.dart';
import '../../domain/models/registration_status.dart';
import '../../domain/models/vehicle_info.dart';
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
    String purpose = 'driver_document',
  }) async {
    final response = await _api.uploadDocument(file, type, purpose: purpose);
    return response['media_url'] as String? ?? '';
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
    final bool isVerified = data['is_verified'] ?? false;
    final List<dynamic> documents = data['documents'] ?? [];
    
    // Simplistic mapping for now to RegistrationStatusInfo
    return RegistrationStatusInfo(
      status: isVerified ? RegistrationStateStatus.approved : RegistrationStateStatus.inReview,
      rejectedReasons: [],
      missingDocuments: [],
    );
  }
}
