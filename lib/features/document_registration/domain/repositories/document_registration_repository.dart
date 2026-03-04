import 'dart:io';
import '../models/bank_account_info.dart';
import '../models/driver_profile_info.dart';
import '../models/registration_status.dart';
import '../models/vehicle_info.dart';

abstract class DocumentRegistrationRepository {
  Future<void> updateProfile(DriverProfileInfo info);
  Future<String> uploadDocument(File file, DocumentType type);
  Future<void> submitVehicleDetails(VehicleInfo info);
  Future<void> submitBankDetails(BankAccountInfo info);
  Future<void> submitFinalConsent(String driverId, bool criminalCheckConsent);
  Future<RegistrationStatusInfo> fetchRegistrationStatus();
}
