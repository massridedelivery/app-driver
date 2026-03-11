import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../domain/models/registration_status.dart';
import '../controllers/registration_controller.dart';

class RegistrationChecklistScreen extends ConsumerWidget {
  const RegistrationChecklistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(registrationControllerProvider);

    if (state.overallStatus == RegistrationStateStatus.inReview) {
      return const _InReviewView();
    }

    if (state.overallStatus == RegistrationStateStatus.approved) {
      return const _ApprovedView();
    }

    if (state.selectedTier == null) {
      return const _TierSelectionView();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'ลงทะเบียนเอกสาร',
          style: AppTypography.heading4.copyWith(
            color: AppColors.semanticGrayNeutralFgHigh,
          ),
        ),
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.semanticGrayNeutralFgHigh,
          ),
          onPressed: () =>
              ref.read(registrationControllerProvider.notifier).setTier(null),
        ),
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
                      'กรุณาเตรียมและอัปโหลดเอกสารต่อไปนี้ให้ครบถ้วน สำหรับประเภท: ${state.selectedTier == KycTier.food
                          ? "อาหาร"
                          : state.selectedTier == KycTier.ride
                          ? "รับส่งคน"
                          : "ทั้งสองประเภท"}',
                      style: AppTypography.caption3.copyWith(
                        color: AppColors.semanticGrayNeutralFgHigh,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: ListView(
                        children: [
                          _buildStepItem(
                            context,
                            title: '1. ข้อมูลส่วนตัว',
                            isComplete: state.isProfileComplete,
                            onTap: () => context.push(
                              '/document-registration/basic-profile',
                            ),
                          ),
                          _buildStepItem(
                            context,
                            title: '2. รูปถ่ายโปรไฟล์',
                            isComplete: state.isProfilePhotoComplete,
                            onTap: () => context.push(
                              '/document-registration/upload-document',
                              extra: {
                                'type': DocumentType.profilePhoto,
                                'title': 'รูปถ่ายโปรไฟล์',
                              },
                            ),
                          ),
                          _buildStepItem(
                            context,
                            title: '3. บัตรประชาชน',
                            isComplete: state.isIdCardComplete,
                            onTap: () => context.push(
                              '/document-registration/upload-document',
                              extra: {
                                'type': DocumentType.idCard,
                                'title': 'บัตรประชาชน',
                              },
                            ),
                          ),

                          // Driving License is required for both, but might be different "type" (Public transport vs Standard)
                          // In our simplified enum, we just have drivingLicense.
                          _buildStepItem(
                            context,
                            title:
                                '4. ${state.selectedTier == KycTier.food ? "ใบขับขี่" : "ใบขับขี่สาธารณะ"}',
                            isComplete: state.isDrivingLicenseComplete,
                            onTap: () => context.push(
                              '/document-registration/upload-document',
                              extra: {
                                'type': DocumentType.drivingLicense,
                                'title': 'ใบขับขี่',
                              },
                            ),
                          ),

                          if (state.selectedTier == KycTier.ride ||
                              state.selectedTier == KycTier.both) ...[
                            _buildStepItem(
                              context,
                              title: '5. ข้อมูลรถ และ สมุดคู่มือ',
                              isComplete: state.isVehicleInfoComplete,
                              onTap: () => context.push(
                                '/document-registration/vehicle-info',
                              ),
                            ),
                            _buildStepItem(
                              context,
                              title: '6. รูปถ่ายตัวรถ',
                              isComplete: state.isVehiclePhotoComplete,
                              onTap: () => context.push(
                                '/document-registration/upload-document',
                                extra: {
                                  'type': DocumentType.vehiclePhoto,
                                  'title': 'รูปถ่ายตัวรถ',
                                },
                              ),
                            ),
                            _buildStepItem(
                              context,
                              title: '7. พ.ร.บ. รถจักรยานยนต์ / ประกัน',
                              isComplete: state.isInsuranceComplete,
                              onTap: () => context.push(
                                '/document-registration/upload-document',
                                extra: {
                                  'type': DocumentType.insurance,
                                  'title': 'พ.ร.บ. / ประกัน',
                                },
                              ),
                            ),
                          ],

                          _buildStepItem(
                            context,
                            title: '8. ข้อมูลบัญชีธนาคาร',
                            isComplete: state.isBankAccountComplete,
                            onTap: () => context.push(
                              '/document-registration/bank-account',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: state.isAllStepsExceptConsentCompleted
                            ? () =>
                                  context.push('/document-registration/consent')
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              state.isAllStepsExceptConsentCompleted
                              ? AppColors.foundationOrange600
                              : AppColors.semanticDisabledBgLow,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'ดำเนินการต่อ',
                          style: AppTypography.label1.copyWith(
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

  Widget _buildStepItem(
    BuildContext context, {
    required String title,
    required bool isComplete,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isComplete ? AppColors.foundationGreen100 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isComplete
              ? AppColors.foundationGreen400
              : AppColors.semanticGrayNeutralBorderLightgray,
        ),
      ),
      child: ListTile(
        title: Text(
          title,
          style: AppTypography.label2.copyWith(
            color: AppColors.semanticGrayNeutralFgHigh,
          ),
        ),
        trailing: isComplete
            ? const Icon(
                Icons.check_circle,
                color: AppColors.foundationGreen500,
              )
            : const Icon(
                Icons.chevron_right,
                color: AppColors.semanticGrayNeutralFgHigh,
              ),
        onTap: onTap,
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.semanticGrayNeutralFgHigh,
          ),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.hourglass_empty,
                size: 80,
                color: AppColors.foundationOrange600,
              ),
              const SizedBox(height: 24),
              Text(
                'เอกสารของคุณกำลังอยู่ระหว่างการตรวจสอบ',
                textAlign: TextAlign.center,
                style: AppTypography.heading3.copyWith(
                  color: AppColors.semanticGrayNeutralFgHigh,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'เราจะแจ้งผลให้คุณทราบเร็วๆนี้',
                style: AppTypography.caption2.copyWith(
                  color: AppColors.semanticGrayNeutralFgHigh,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ApprovedView extends StatelessWidget {
  const _ApprovedView();

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
              const Icon(
                Icons.check_circle,
                size: 80,
                color: AppColors.foundationGreen500,
              ),
              const SizedBox(height: 24),
              Text(
                'เอกสารของคุณผ่านการอนุมัติแล้ว',
                textAlign: TextAlign.center,
                style: AppTypography.heading3.copyWith(
                  color: AppColors.semanticGrayNeutralFgHigh,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'คุณสามารถเริ่มรับงานได้ทันที',
                style: AppTypography.caption2.copyWith(
                  color: AppColors.semanticGrayNeutralFgHigh,
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => context.go('/home'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.foundationOrange600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'ไปหน้ารับงาน',
                    style: AppTypography.label1.copyWith(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TierSelectionView extends ConsumerWidget {
  const _TierSelectionView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'เลือกประเภทการขับขี่',
          style: AppTypography.heading4.copyWith(
            color: AppColors.semanticGrayNeutralFgHigh,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.semanticGrayNeutralFgHigh,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'ข้อมูลเอกสารที่ต้องใช้จะแตกต่างกันตามประเภทที่คุณเลือก',
                style: AppTypography.caption2.copyWith(
                  color: AppColors.semanticGrayNeutralFgHigh,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Expanded(
                child: ListView(
                  children: [
                    _buildTierCard(
                      context,
                      ref: ref,
                      tier: KycTier.food,
                      title: 'ส่งอาหาร (FOOD)',
                      description:
                          'ใช้เพียงบัตรประชาชน ใบขับขี่ทั่วไป และรูปเซลฟี่\n(ขับรับส่งอาหารเท่านั้น)',
                      icon: Icons.fastfood,
                    ),
                    _buildTierCard(
                      context,
                      ref: ref,
                      tier: KycTier.ride,
                      title: 'รับส่งคน (RIDE)',
                      description:
                          'เพิ่มเอกสารรถ พ.ร.บ. ประกัน และใบขับขี่สาธารณะ\n(ขับรับส่งผู้โดยสารเท่านั้น)',
                      icon: Icons.directions_car,
                    ),
                    _buildTierCard(
                      context,
                      ref: ref,
                      tier: KycTier.both,
                      title: 'ขับทั้งคู่ (BOTH)',
                      description: 'เตรียมเอกสารจัดเต็ม รับงานได้ทุกประเภท',
                      icon: Icons.two_wheeler,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTierCard(
    BuildContext context, {
    required WidgetRef ref,
    required KycTier tier,
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          ref.read(registrationControllerProvider.notifier).setTier(tier);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border.all(
              color: AppColors.semanticGrayNeutralBorderLightgray,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.foundationOrange100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: AppColors.foundationOrange600,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.heading6.copyWith(
                        color: AppColors.semanticGrayNeutralFgHigh,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: AppTypography.caption4.copyWith(
                        color: AppColors.semanticGrayNeutralFgMidOnWhite,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.semanticGrayNeutralFgHigh,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
