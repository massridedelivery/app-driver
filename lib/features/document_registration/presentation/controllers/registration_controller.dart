import 'dart:io';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../dependency_injection.dart';
import '../../domain/models/bank_account_info.dart';
import '../../domain/models/driver_profile_info.dart';
import '../../domain/models/registration_status.dart';
import '../../domain/models/vehicle_info.dart';
import '../../domain/repositories/document_registration_repository.dart';
import '../states/registration_state.dart';

part 'registration_controller.g.dart';

@riverpod
class RegistrationController extends _$RegistrationController {
  late final DocumentRegistrationRepository _repository;

  @override
  RegistrationState build() {
    _repository = getIt<DocumentRegistrationRepository>();
    return const RegistrationState();
  }

  Future<void> fetchStatus() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final statusInfo = await _repository.fetchRegistrationStatus();
      state = state.copyWith(
        isLoading: false,
        overallStatus: statusInfo.status,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> updateProfile(DriverProfileInfo info) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.updateProfile(info);
      state = state.copyWith(isLoading: false, isProfileComplete: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> uploadDocument(File file, DocumentType type) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.uploadDocument(file, type);
      
      // Update the specific flag based on the document type
      bool isProfilePhoto = state.isProfilePhotoComplete;
      bool isIdCard = state.isIdCardComplete;
      bool isDrivingLicense = state.isDrivingLicenseComplete;
      bool isVehiclePhoto = state.isVehiclePhotoComplete;
      bool isInsurance = state.isInsuranceComplete;
      
      switch (type) {
        case DocumentType.profilePhoto:
          isProfilePhoto = true;
          break;
        case DocumentType.idCard:
          isIdCard = true;
          break;
        case DocumentType.drivingLicense:
          isDrivingLicense = true;
          break;
        case DocumentType.vehiclePhoto:
          isVehiclePhoto = true;
          break;
        case DocumentType.insurance:
          isInsurance = true;
          break;
        default:
          break;
      }
      
      state = state.copyWith(
        isLoading: false,
        isProfilePhotoComplete: isProfilePhoto,
        isIdCardComplete: isIdCard,
        isDrivingLicenseComplete: isDrivingLicense,
        isVehiclePhotoComplete: isVehiclePhoto,
        isInsuranceComplete: isInsurance,
      );
      
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> submitVehicleDetails(VehicleInfo info, File? greenBookFile) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      if (greenBookFile != null) {
        await _repository.uploadDocument(greenBookFile, DocumentType.vehicleRegistration);
      }
      await _repository.submitVehicleDetails(info);
      
      state = state.copyWith(isLoading: false, isVehicleInfoComplete: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> submitBankDetails(BankAccountInfo info, File? passbookFile) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      if (passbookFile != null) {
        await _repository.uploadDocument(passbookFile, DocumentType.bankPassbook);
      }
      await _repository.submitBankDetails(info);
      
      state = state.copyWith(isLoading: false, isBankAccountComplete: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> submitApplication(String driverId, bool consent) async {
    if (!state.isAllStepsExceptConsentCompleted) {
      state = state.copyWith(errorMessage: 'Please complete all previous steps first.');
      return false;
    }
    
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.submitFinalConsent(driverId, consent);
      state = state.copyWith(
        isLoading: false,
        isConsentGiven: true,
        overallStatus: RegistrationStateStatus.inReview,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }
}
