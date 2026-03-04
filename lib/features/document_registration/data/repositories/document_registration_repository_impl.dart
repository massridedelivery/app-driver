import 'dart:io';
import 'package:injectable/injectable.dart';
import '../../domain/models/bank_account_info.dart';
import '../../domain/models/driver_profile_info.dart';
import '../../domain/models/registration_status.dart';
import '../../domain/models/vehicle_info.dart';
import '../../domain/repositories/document_registration_repository.dart';
import '../sources/mock_document_registration_api.dart';

@LazySingleton(as: DocumentRegistrationRepository)
class DocumentRegistrationRepositoryImpl implements DocumentRegistrationRepository {
  final MockDocumentRegistrationApi _mockApi;

  DocumentRegistrationRepositoryImpl(this._mockApi);

  @override
  Future<void> updateProfile(DriverProfileInfo info) async {
    await _mockApi.updateProfile(info);
  }

  @override
  Future<String> uploadDocument(File file, DocumentType type) async {
    final response = await _mockApi.uploadDocument(file, type);
    return response['url'] as String;
  }

  @override
  Future<void> submitVehicleDetails(VehicleInfo info) async {
    await _mockApi.submitVehicleDetails(info);
  }

  @override
  Future<void> submitBankDetails(BankAccountInfo info) async {
    await _mockApi.submitBankDetails(info);
  }

  @override
  Future<void> submitFinalConsent(String driverId, bool criminalCheckConsent) async {
    await _mockApi.submitFinalConsent(driverId, criminalCheckConsent);
  }

  @override
  Future<RegistrationStatusInfo> fetchRegistrationStatus() async {
    final data = await _mockApi.fetchRegistrationStatus();
    return RegistrationStatusInfo.fromMap(data);
  }
}
