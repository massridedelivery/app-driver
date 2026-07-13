import 'package:massdrive/features/document_registration/domain/models/bank_account_info.dart';
import 'package:massdrive/features/document_registration/domain/models/driver_profile_info.dart';
import 'package:massdrive/features/document_registration/domain/models/vehicle_info.dart';
import 'package:massdrive/features/document_registration/domain/models/driver_document_model.dart';

import '../../domain/models/registration_status.dart';

class RegistrationState {
  final bool isLoading;
  final String? errorMessage;

  // Step 1
  final bool isProfileComplete;

  // Step 2
  final bool isProfilePhotoComplete;

  // Step 3
  final bool isIdCardComplete;

  // Step 4
  final bool isDrivingLicenseComplete;

  final bool isPublicDrivingLicenseComplete;

  // Step 5
  final bool isVehicleInfoComplete;

  // Step 6
  final bool isVehiclePhotoComplete;

  // Step 7
  final bool isInsuranceComplete;

  // Step 8
  final bool isBankAccountComplete;

  // Step 9
  final bool isConsentGiven;

  final KycTier? selectedTier;
  final RegistrationStateStatus overallStatus;

  // Persisted Form Data
  final DriverProfileInfo? profileInfo;
  final VehicleInfo? vehicleInfo;
  final BankAccountInfo? bankAccountInfo;
  final Map<DocumentType, String> uploadedDocuments;
  final Map<DocumentType, DriverDocumentModel> remoteDocuments;

  const RegistrationState({
    this.isLoading = false,
    this.errorMessage,
    this.isProfileComplete = false,
    this.isProfilePhotoComplete = false,
    this.isIdCardComplete = false,
    this.isDrivingLicenseComplete = false,
    this.isPublicDrivingLicenseComplete = false,
    this.isVehicleInfoComplete = false,
    this.isVehiclePhotoComplete = false,
    this.isInsuranceComplete = false,
    this.isBankAccountComplete = false,
    this.isConsentGiven = false,
    this.selectedTier,
    this.overallStatus = RegistrationStateStatus.pending,
    this.profileInfo,
    this.vehicleInfo,
    this.bankAccountInfo,
    this.uploadedDocuments = const {},
    this.remoteDocuments = const {},
  });

  bool get isAllStepsExceptConsentCompleted {
    if (selectedTier == null) return false;

    // Core always required
    if (!isProfileComplete ||
        !isIdCardComplete ||
        !isBankAccountComplete ||
        !isProfilePhotoComplete ||
        !isDrivingLicenseComplete) {
      return false;
    }

    // Tier specific requirements
    if (selectedTier == KycTier.food) {
      return true;
    } else if (selectedTier == KycTier.ride) {
      return isPublicDrivingLicenseComplete &&
          isVehicleInfoComplete &&
          isVehiclePhotoComplete &&
          isInsuranceComplete;
    } else {
      // BOTH
      return isPublicDrivingLicenseComplete &&
          isVehicleInfoComplete &&
          isVehiclePhotoComplete &&
          isInsuranceComplete;
    }
  }

  RegistrationState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isProfileComplete,
    bool? isProfilePhotoComplete,
    bool? isIdCardComplete,
    bool? isDrivingLicenseComplete,
    bool? isPublicDrivingLicenseComplete,
    bool? isVehicleInfoComplete,
    bool? isVehiclePhotoComplete,
    bool? isInsuranceComplete,
    bool? isBankAccountComplete,
    bool? isConsentGiven,
    KycTier? selectedTier,
    RegistrationStateStatus? overallStatus,
    DriverProfileInfo? profileInfo,
    VehicleInfo? vehicleInfo,
    BankAccountInfo? bankAccountInfo,
    Map<DocumentType, String>? uploadedDocuments,
    Map<DocumentType, DriverDocumentModel>? remoteDocuments,
  }) {
    return RegistrationState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      isProfilePhotoComplete:
          isProfilePhotoComplete ?? this.isProfilePhotoComplete,
      isIdCardComplete: isIdCardComplete ?? this.isIdCardComplete,
      isDrivingLicenseComplete:
          isDrivingLicenseComplete ?? this.isDrivingLicenseComplete,
      isPublicDrivingLicenseComplete:
          isPublicDrivingLicenseComplete ?? this.isPublicDrivingLicenseComplete,
      isVehicleInfoComplete:
          isVehicleInfoComplete ?? this.isVehicleInfoComplete,
      isVehiclePhotoComplete:
          isVehiclePhotoComplete ?? this.isVehiclePhotoComplete,
      isInsuranceComplete: isInsuranceComplete ?? this.isInsuranceComplete,
      isBankAccountComplete:
          isBankAccountComplete ?? this.isBankAccountComplete,
      isConsentGiven: isConsentGiven ?? this.isConsentGiven,
      selectedTier: selectedTier ?? this.selectedTier,
      overallStatus: overallStatus ?? this.overallStatus,
      profileInfo: profileInfo ?? this.profileInfo,
      vehicleInfo: vehicleInfo ?? this.vehicleInfo,
      bankAccountInfo: bankAccountInfo ?? this.bankAccountInfo,
      uploadedDocuments: uploadedDocuments ?? this.uploadedDocuments,
      remoteDocuments: remoteDocuments ?? this.remoteDocuments,
    );
  }
}
