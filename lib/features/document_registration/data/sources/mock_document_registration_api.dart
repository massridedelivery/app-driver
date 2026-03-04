import 'dart:io';
import 'package:injectable/injectable.dart';
import '../../domain/models/bank_account_info.dart';
import '../../domain/models/driver_profile_info.dart';
import '../../domain/models/registration_status.dart';
import '../../domain/models/vehicle_info.dart';

@lazySingleton
class MockDocumentRegistrationApi {
  // Mock endpoint: POST /api/v1/driver/profile
  Future<Map<String, dynamic>> updateProfile(DriverProfileInfo info) async {
    await Future.delayed(const Duration(seconds: 1));
    return {
      'message': 'Profile saved successfully',
      'status': 'pending_documents',
    };
  }

  // Mock endpoint: POST /api/v1/driver/documents/upload
  Future<Map<String, dynamic>> uploadDocument(File file, DocumentType type) async {
    await Future.delayed(const Duration(seconds: 2));
    String typeStr = type.name;
    return {
      'documentId': 'doc_${DateTime.now().millisecondsSinceEpoch}',
      'url': 'https://mock-storage.com/documents/doc_${DateTime.now().millisecondsSinceEpoch}.jpg',
      'type': typeStr,
      'status': 'uploaded',
    };
  }

  // Mock endpoint: POST /api/v1/driver/vehicle
  Future<Map<String, dynamic>> submitVehicleDetails(VehicleInfo info) async {
    await Future.delayed(const Duration(seconds: 1));
    return {
      'message': 'Vehicle details saved',
    };
  }

  // Mock endpoint: POST /api/v1/driver/bank-account
  Future<Map<String, dynamic>> submitBankDetails(BankAccountInfo info) async {
    await Future.delayed(const Duration(seconds: 1));
    return {
      'message': 'Bank details saved',
    };
  }

  // Mock endpoint: POST /api/v1/driver/documents/submit
  Future<Map<String, dynamic>> submitFinalConsent(String driverId, bool criminalCheckConsent) async {
    await Future.delayed(const Duration(seconds: 1));
    if (!criminalCheckConsent) {
      throw Exception("Consent is required");
    }
    return {
      'message': 'All documents submitted for review',
      'status': 'in_review',
    };
  }

  // Mock endpoint: GET /api/v1/driver/status
  Future<Map<String, dynamic>> fetchRegistrationStatus() async {
    await Future.delayed(const Duration(seconds: 1));
    return {
      'status': 'pending', // Could be 'in_review', 'approved', 'rejected' test as needed
      'rejectedReasons': [],
      'missingDocuments': [],
    };
  }
}
