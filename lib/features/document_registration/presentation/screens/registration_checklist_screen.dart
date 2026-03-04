import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../controllers/registration_controller.dart';
import '../../domain/models/registration_status.dart';

class RegistrationChecklistScreen extends ConsumerWidget {
  const RegistrationChecklistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(registrationControllerProvider);

    if (state.overallStatus == RegistrationStateStatus.inReview) {
      return const _InReviewView();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'ลงทะเบียนเอกสาร',
          style: AppTypography.heading3.copyWith(color: AppColors.semanticGrayNeutralFgHigh),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: state.isLoading && !state.isProfileComplete
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'กรุณาเตรียมและอัปโหลดเอกสารต่อไปนี้ให้ครบถ้วน',
                      style: AppTypography.caption2.copyWith(color: AppColors.semanticGrayNeutralFgHigh),
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: ListView(
                        children: [
                          _buildStepItem(
                            context,
                            title: '1. ข้อมูลส่วนตัว',
                            isComplete: state.isProfileComplete,
                            onTap: () => context.push('/document-registration/basic-profile'),
                          ),
                          _buildStepItem(
                            context,
                            title: '2. รูปถ่ายโปรไฟล์',
                            isComplete: state.isProfilePhotoComplete,
                            onTap: () => context.push(
                              '/document-registration/upload-document', 
                              extra: {'type': DocumentType.profilePhoto, 'title': 'รูปถ่ายโปรไฟล์'}
                            ),
                          ),
                          _buildStepItem(
                            context,
                            title: '3. บัตรประชาชน',
                            isComplete: state.isIdCardComplete,
                            onTap: () => context.push(
                              '/document-registration/upload-document', 
                              extra: {'type': DocumentType.idCard, 'title': 'บัตรประชาชน'}
                            ),
                          ),
                          _buildStepItem(
                            context,
                            title: '4. ใบขับขี่รถจักรยานยนต์',
                            isComplete: state.isDrivingLicenseComplete,
                            onTap: () => context.push(
                              '/document-registration/upload-document', 
                              extra: {'type': DocumentType.drivingLicense, 'title': 'ใบขับขี่รถจักรยานยนต์'}
                            ),
                          ),
                          _buildStepItem(
                            context,
                            title: '5. ข้อมูลรถ และ สมุดคู่มือ',
                            isComplete: state.isVehicleInfoComplete,
                            onTap: () => context.push('/document-registration/vehicle-info'),
                          ),
                          _buildStepItem(
                            context,
                            title: '6. รูปถ่ายตัวรถ',
                            isComplete: state.isVehiclePhotoComplete,
                            onTap: () => context.push(
                              '/document-registration/upload-document', 
                              extra: {'type': DocumentType.vehiclePhoto, 'title': 'รูปถ่ายตัวรถ'}
                            ),
                          ),
                          _buildStepItem(
                            context,
                            title: '7. พ.ร.บ. รถจักรยานยนต์',
                            isComplete: state.isInsuranceComplete,
                            onTap: () => context.push(
                              '/document-registration/upload-document', 
                              extra: {'type': DocumentType.insurance, 'title': 'พ.ร.บ. รถจักรยานยนต์'}
                            ),
                          ),
                          _buildStepItem(
                            context,
                            title: '8. ข้อมูลบัญชีธนาคาร',
                            isComplete: state.isBankAccountComplete,
                            onTap: () => context.push('/document-registration/bank-account'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: state.isAllStepsExceptConsentCompleted
                            ? () => context.push('/document-registration/consent')
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: state.isAllStepsExceptConsentCompleted
                              ? AppColors.foundationOrange600
                              : AppColors.semanticDisabledBgLow,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'ดำเนินการต่อ',
                          style: AppTypography.subtitle1.copyWith(
                            color: state.isAllStepsExceptConsentCompleted
                                ? Colors.white
                                : AppColors.semanticDisabledFgOnWhite,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStepItem(BuildContext context, {required String title, required bool isComplete, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isComplete ? AppColors.foundationGreen100 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isComplete ? AppColors.foundationGreen400 : AppColors.semanticGrayNeutralBorderLightgray,
        ),
      ),
      child: ListTile(
        title: Text(
          title,
          style: AppTypography.subtitle2.copyWith(
            color: AppColors.semanticGrayNeutralFgHigh,
          ),
        ),
        trailing: isComplete
            ? const Icon(Icons.check_circle, color: AppColors.foundationGreen500)
            : const Icon(Icons.chevron_right, color: AppColors.semanticGrayNeutralFgHigh),
        onTap: isComplete ? null : onTap,
      ),
    );
  }
}

class _InReviewView extends StatelessWidget {
  const _InReviewView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.hourglass_empty, size: 80, color: AppColors.foundationOrange600),
              const SizedBox(height: 24),
              Text(
                'เอกสารของคุณกำลังอยู่ระหว่างการตรวจสอบ',
                textAlign: TextAlign.center,
                style: AppTypography.heading3.copyWith(color: AppColors.semanticGrayNeutralFgHigh),
              ),
              const SizedBox(height: 16),
              Text(
                'เราจะแจ้งผลให้คุณทราบเร็วๆนี้',
                style: AppTypography.caption2.copyWith(color: AppColors.semanticGrayNeutralFgHigh),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
