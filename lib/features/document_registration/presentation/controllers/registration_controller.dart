import 'dart:io';
import 'package:massdrive/core/constants/media_category.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../dependency_injection.dart';
import '../../../profile/presentation/controllers/profile_controller.dart';
import '../../domain/models/bank_account_info.dart';
import '../../domain/models/driver_profile_info.dart';
import '../../domain/models/registration_status.dart';
import '../../domain/models/vehicle_info.dart';
import '../../domain/models/driver_document_model.dart';
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

  void setTier(KycTier? tier) {
    if (tier == null) {
      state = RegistrationState(
        isLoading: state.isLoading,
        errorMessage: state.errorMessage,
        isProfileComplete: state.isProfileComplete,
        isProfilePhotoComplete: state.isProfilePhotoComplete,
        isIdCardComplete: state.isIdCardComplete,
        isDrivingLicenseComplete: state.isDrivingLicenseComplete,
        isVehicleInfoComplete: state.isVehicleInfoComplete,
        isVehiclePhotoComplete: state.isVehiclePhotoComplete,
        isInsuranceComplete: state.isInsuranceComplete,
        isBankAccountComplete: state.isBankAccountComplete,
        isConsentGiven: state.isConsentGiven,
        selectedTier: null,
        overallStatus: state.overallStatus,
      );
    } else {
      state = state.copyWith(selectedTier: tier);
    }
  }

  Future<void> fetchStatus() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final statusInfo = await _repository.fetchRegistrationStatus();
      final docList = await _repository.fetchDocuments();
      
      final profileNotifier = ref.read(profileControllerProvider.notifier);
      await profileNotifier.fetchProfile();
      final profile = ref.read(profileControllerProvider).profile;

      final Map<DocumentType, DriverDocumentModel> remoteDocs = {};
      for (final doc in docList) {
        DocumentType? type;
        if (doc.docType == 'selfie') {
          type = DocumentType.profilePhoto;
        } else if (doc.docType == 'id_card') {
          type = DocumentType.idCard;
        } else if (doc.docType == 'driver_license' || doc.docType == 'public_transport_license') {
          type = DocumentType.drivingLicense;
        } else if (doc.docType == 'vehicle_registration') {
          type = DocumentType.vehicleRegistration;
        } else if (doc.docType == 'insurance') {
          type = DocumentType.insurance;
        } else if (doc.docType == 'vehicle_photo') {
          type = DocumentType.vehiclePhoto;
        } else if (doc.docType == 'bank_passbook') {
          type = DocumentType.bankPassbook;
        }
        
        if (type != null) {
          remoteDocs[type] = doc;
        }
      }

      final isProfileComplete = profile != null &&
          profile.fullName.isNotEmpty &&
          profile.phone != null &&
          profile.phone!.isNotEmpty;

      final isProfilePhotoComplete = remoteDocs[DocumentType.profilePhoto]?.status == 'approved' ||
          remoteDocs[DocumentType.profilePhoto]?.status == 'pending';

      final isIdCardComplete = remoteDocs[DocumentType.idCard]?.status == 'approved' ||
          remoteDocs[DocumentType.idCard]?.status == 'pending';

      final isDrivingLicenseComplete = remoteDocs[DocumentType.drivingLicense]?.status == 'approved' ||
          remoteDocs[DocumentType.drivingLicense]?.status == 'pending';

      final isVehicleRegistrationComplete = remoteDocs[DocumentType.vehicleRegistration]?.status == 'approved' ||
          remoteDocs[DocumentType.vehicleRegistration]?.status == 'pending';

      final isInsuranceComplete = remoteDocs[DocumentType.insurance]?.status == 'approved' ||
          remoteDocs[DocumentType.insurance]?.status == 'pending';

      final isBankAccountComplete = state.isBankAccountComplete ||
          remoteDocs[DocumentType.bankPassbook]?.status == 'approved' ||
          remoteDocs[DocumentType.bankPassbook]?.status == 'pending';

      final isVehiclePhotoComplete = state.isVehiclePhotoComplete ||
          remoteDocs[DocumentType.vehiclePhoto]?.status == 'approved' ||
          remoteDocs[DocumentType.vehiclePhoto]?.status == 'pending';

      final isVehicleInfoComplete = profile != null &&
          profile.vehiclePlate != null &&
          profile.vehiclePlate!.isNotEmpty &&
          isVehicleRegistrationComplete;

      state = state.copyWith(
        isLoading: false,
        overallStatus: statusInfo.status,
        remoteDocuments: remoteDocs,
        isProfileComplete: isProfileComplete,
        isProfilePhotoComplete: isProfilePhotoComplete,
        isIdCardComplete: isIdCardComplete,
        isDrivingLicenseComplete: isDrivingLicenseComplete,
        isVehicleInfoComplete: isVehicleInfoComplete,
        isVehiclePhotoComplete: isVehiclePhotoComplete,
        isInsuranceComplete: isInsuranceComplete,
        isBankAccountComplete: isBankAccountComplete,
        profileInfo: profile != null
            ? DriverProfileInfo(
                firstName: profile.fullName.split(' ').first,
                lastName: profile.fullName.split(' ').skip(1).join(' '),
                email: '',
                emergencyContact: '',
              )
            : null,
        vehicleInfo: profile != null && profile.vehiclePlate != null
            ? VehicleInfo(
                vehicleType: 'motorcycle',
                brand: '',
                model: profile.vehicleModel ?? '',
                year: profile.vehicleYear ?? 0,
                licensePlate: profile.vehiclePlate ?? '',
              )
            : null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> updateProfile(DriverProfileInfo info) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.updateProfile(info);
      state = state.copyWith(
        isLoading: false,
        isProfileComplete: true,
        profileInfo: info,
      );
      await fetchStatus();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> uploadDocument(File file, DocumentType type, {String? docNumber}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      // Map DocumentType to the correct MediaCategory
      MediaCategory category;
      if (type == DocumentType.profilePhoto) {
        category = MediaCategory.avatar;
      } else {
        category = MediaCategory.driverDoc;
      }

      final isUpdate = state.remoteDocuments.containsKey(type);
      
      String? docTypeOverride;
      if (type == DocumentType.drivingLicense) {
        if (state.selectedTier == KycTier.food) {
          docTypeOverride = 'driver_license';
        } else {
          docTypeOverride = 'public_transport_license';
        }
      }

      await _repository.uploadDocument(
        file,
        type,
        category: category,
        docNumber: docNumber,
        isUpdate: isUpdate,
        docTypeOverride: docTypeOverride,
      );

      final updatedDocs = Map<DocumentType, String>.from(
        state.uploadedDocuments,
      );
      updatedDocs[type] = file.path;

      state = state.copyWith(
        uploadedDocuments: updatedDocs,
      );

      await fetchStatus();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> submitVehicleDetails(
    VehicleInfo info,
    File? greenBookFile,
  ) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      if (greenBookFile != null) {
        final isUpdate = state.remoteDocuments.containsKey(DocumentType.vehicleRegistration);
        await _repository.uploadDocument(
          greenBookFile,
          DocumentType.vehicleRegistration,
          category: MediaCategory.driverDoc,
          docNumber: info.licensePlate,
          isUpdate: isUpdate,
        );
      }
      await _repository.submitVehicleDetails(info);

      final updatedDocs = Map<DocumentType, String>.from(
        state.uploadedDocuments,
      );
      if (greenBookFile != null) {
        updatedDocs[DocumentType.vehicleRegistration] = greenBookFile.path;
      }

      state = state.copyWith(
        isVehicleInfoComplete: true,
        vehicleInfo: info,
        uploadedDocuments: updatedDocs,
      );

      await fetchStatus();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> submitBankDetails(
    BankAccountInfo info,
    File? passbookFile,
  ) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      if (passbookFile != null) {
        final isUpdate = state.remoteDocuments.containsKey(DocumentType.bankPassbook);
        await _repository.uploadDocument(
          passbookFile,
          DocumentType.bankPassbook,
          category: MediaCategory.driverDoc,
          docNumber: info.accountNumber,
          isUpdate: isUpdate,
        );
      }
      await _repository.submitBankDetails(info);

      final updatedDocs = Map<DocumentType, String>.from(
        state.uploadedDocuments,
      );
      if (passbookFile != null) {
        updatedDocs[DocumentType.bankPassbook] = passbookFile.path;
      }

      state = state.copyWith(
        isBankAccountComplete: true,
        bankAccountInfo: info,
        uploadedDocuments: updatedDocs,
      );

      await fetchStatus();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> submitApplication(String driverId, bool consent) async {
    if (!state.isAllStepsExceptConsentCompleted) {
      state = state.copyWith(
        errorMessage: 'Please complete all previous steps first.',
      );
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.submitFinalConsent(driverId, consent);
      state = state.copyWith(
        isConsentGiven: true,
        overallStatus: RegistrationStateStatus.inReview,
      );
      await fetchStatus();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }
}
