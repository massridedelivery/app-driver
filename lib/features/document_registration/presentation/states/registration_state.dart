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

  final RegistrationStateStatus overallStatus;

  const RegistrationState({
    this.isLoading = false,
    this.errorMessage,
    this.isProfileComplete = false,
    this.isProfilePhotoComplete = false,
    this.isIdCardComplete = false,
    this.isDrivingLicenseComplete = false,
    this.isVehicleInfoComplete = false,
    this.isVehiclePhotoComplete = false,
    this.isInsuranceComplete = false,
    this.isBankAccountComplete = false,
    this.isConsentGiven = false,
    this.overallStatus = RegistrationStateStatus.pending,
  });

  bool get isAllStepsExceptConsentCompleted =>
      isProfileComplete &&
      isProfilePhotoComplete &&
      isIdCardComplete &&
      isDrivingLicenseComplete &&
      isVehicleInfoComplete &&
      isVehiclePhotoComplete &&
      isInsuranceComplete &&
      isBankAccountComplete;

  RegistrationState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isProfileComplete,
    bool? isProfilePhotoComplete,
    bool? isIdCardComplete,
    bool? isDrivingLicenseComplete,
    bool? isVehicleInfoComplete,
    bool? isVehiclePhotoComplete,
    bool? isInsuranceComplete,
    bool? isBankAccountComplete,
    bool? isConsentGiven,
    RegistrationStateStatus? overallStatus,
  }) {
    return RegistrationState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      isProfilePhotoComplete: isProfilePhotoComplete ?? this.isProfilePhotoComplete,
      isIdCardComplete: isIdCardComplete ?? this.isIdCardComplete,
      isDrivingLicenseComplete: isDrivingLicenseComplete ?? this.isDrivingLicenseComplete,
      isVehicleInfoComplete: isVehicleInfoComplete ?? this.isVehicleInfoComplete,
      isVehiclePhotoComplete: isVehiclePhotoComplete ?? this.isVehiclePhotoComplete,
      isInsuranceComplete: isInsuranceComplete ?? this.isInsuranceComplete,
      isBankAccountComplete: isBankAccountComplete ?? this.isBankAccountComplete,
      isConsentGiven: isConsentGiven ?? this.isConsentGiven,
      overallStatus: overallStatus ?? this.overallStatus,
    );
  }
}
