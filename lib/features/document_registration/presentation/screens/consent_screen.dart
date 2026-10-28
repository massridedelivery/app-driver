import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:massdrive/core/theme/brand_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../profile/presentation/controllers/profile_controller.dart';
import '../controllers/registration_controller.dart';
import '../widgets/registration_ui.dart';

class ConsentScreen extends ConsumerStatefulWidget {
  const ConsentScreen({super.key});

  @override
  ConsumerState<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends ConsumerState<ConsentScreen> {
  bool _isConsentChecked = false;

  void _submit() async {
    final success = await ref
        .read(registrationControllerProvider.notifier)
        .submitApplication(true);

    if (success && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => RegistrationSuccessDialog(
          onConfirm: () {
            Navigator.pop(ctx); // close the dialog
            // Refresh the profile so home shows the "under review" state,
            // then return to the home page (clears the registration stack).
            ref.read(profileControllerProvider.notifier).fetchProfile();
            context.go(AppRoutes.homeNamedPage);
          },
        ),
      );
    } else if (mounted) {
      final state = ref.read(registrationControllerProvider);
      if (state.errorMessage != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(registrationControllerProvider);
    final brand = context.brand;
    final tier = state.selectedTier;
    // Consent is only reachable once every checklist item is done; summarise
    // them (profile + N documents + bank).
    final docCount = tier == null ? null : registrationTotalSteps(tier) - 2;

    return RegistrationScaffold(
      icon: Icons.draw_rounded,
      title: 'ยืนยันและส่งเอกสาร',
      step: registrationStepNumber(tier, RegistrationItem.consent),
      total: tier == null ? null : registrationTotalSteps(tier),
      bottom: RegistrationPrimaryButton(
        label: 'ส่งแบบฟอร์มลงทะเบียน',
        loading: state.isLoading,
        onPressed: (_isConsentChecked && !state.isLoading) ? _submit : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (docCount != null)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: brand.okBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final line in [
                    'ข้อมูลส่วนตัว',
                    'เอกสาร $docCount รายการ',
                    'บัญชีธนาคาร',
                  ])
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 17,
                            color: brand.ok,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            line,
                            style: AppTypography.label3.copyWith(
                              color: brand.ok,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: brand.fill,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'หนังสือยินยอมการตรวจประวัติอาชญากรรม',
                  style: AppTypography.label2.copyWith(color: brand.text1),
                ),
                const SizedBox(height: 6),
                Text(
                  'ข้าพเจ้ายินยอมให้บริษัทดำเนินการตรวจสอบประวัติอาชญากรรมของข้าพเจ้าต่อสำนักงานตำรวจแห่งชาติ หรือหน่วยงานที่เกี่ยวข้อง เพื่อใช้เป็นส่วนหนึ่งในการพิจารณารับเป็นผู้ขับขี่ของบริษัท',
                  style: AppTypography.body3.copyWith(
                    color: brand.text2,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => setState(() => _isConsentChecked = !_isConsentChecked),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _isConsentChecked,
                      onChanged: (val) {
                        setState(() {
                          _isConsentChecked = val ?? false;
                        });
                      },
                      activeColor: brand.red,
                      checkColor: Colors.white,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      side: BorderSide(color: brand.text3, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'ข้าพเจ้ายินยอมตามเงื่อนไขดังกล่าว',
                      style: AppTypography.label3.copyWith(
                        fontSize: 13,
                        color: brand.text1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "ส่งข้อมูลสำเร็จ" dialog shown after the application is submitted.
class RegistrationSuccessDialog extends StatelessWidget {
  final VoidCallback onConfirm;

  const RegistrationSuccessDialog({super.key, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return Dialog(
      backgroundColor: brand.surface,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const RegistrationResultContent(
              icon: Icons.task_alt_rounded,
              title: 'ส่งข้อมูลสำเร็จ',
              body:
                  'ระบบได้รับข้อมูลของท่านแล้ว และกำลังอยู่ในขั้นตอนการตรวจสอบ จะมีการแจ้งเตือนอีกครั้งเมื่อผลการพิจารณาเสร็จสิ้น',
              extra: RegistrationTimeline(),
            ),
            const SizedBox(height: 20),
            RegistrationPrimaryButton(label: 'ตกลง', onPressed: onConfirm),
          ],
        ),
      ),
    );
  }
}
