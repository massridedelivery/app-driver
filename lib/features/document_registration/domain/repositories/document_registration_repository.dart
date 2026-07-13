import 'dart:io';
import 'package:massdrive/core/constants/media_category.dart';
import '../models/bank_account_info.dart';
import '../models/driver_profile_info.dart';
import '../models/registration_status.dart';
import '../models/vehicle_info.dart';
import '../models/driver_document_model.dart';

abstract class DocumentRegistrationRepository {
  Future<void> updateProfile(DriverProfileInfo info);
  Future<String> uploadDocument(
    File file,
    DocumentType type, {
    MediaCategory category = MediaCategory.driverDoc,
    String? docNumber,
    bool isUpdate = false,
    String? docTypeOverride,
  });
  Future<void> submitVehicleDetails(VehicleInfo info);
  Future<void> submitBankDetails(BankAccountInfo info);
  Future<void> submitFinalConsent(String driverId, bool criminalCheckConsent);
  Future<RegistrationStatusInfo> fetchRegistrationStatus();
  Future<List<DriverDocumentModel>> fetchDocuments();
  Future<String> getTemporaryViewUrl(String fileKey);
}
