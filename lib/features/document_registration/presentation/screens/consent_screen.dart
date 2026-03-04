import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../controllers/registration_controller.dart';

class ConsentScreen extends ConsumerStatefulWidget {
  const ConsentScreen({super.key});

  @override
  ConsumerState<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends ConsumerState<ConsentScreen> {
  bool _isConsentChecked = false;

  void _submit() async {
    final success = await ref.read(registrationControllerProvider.notifier)
        .submitApplication("mock_driver_123", true);
        
    if (success && mounted) {
      // Navigate to Home or simply show success message
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('ส่งข้อมูลสำเร็จ'),
          content: const Text('ระบบได้รับข้อมูลของท่านแล้ว และกำลังอยู่ในขั้นตอนการตรวจสอบ จะมีการแจ้งเตือนอีกครั้งเมื่อผลการพิจารณาเสร็จสิ้น'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.pop(); // Pop dialog
              },
              child: const Text('ตกลง'),
            )
          ],
        ),
      );
    } else if (mounted) {
      final state = ref.read(registrationControllerProvider);
      if (state.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(registrationControllerProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('9. ยืนยันและส่งเอกสาร', style: AppTypography.heading3.copyWith(color: AppColors.semanticGrayNeutralFgHigh)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.semanticGrayNeutralFgHigh),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.description_outlined, size: 80, color: AppColors.foundationOrange600),
            const SizedBox(height: 24),
            Text(
              'หนังสือยินยอมการตรวจประวัติอาชญากรรม',
              style: AppTypography.heading3.copyWith(color: AppColors.semanticGrayNeutralFgHigh),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'ข้าพเจ้ายินยอมให้บริษัทดำเนินการตรวจสอบประวัติอาชญากรรมของข้าพเจ้าต่อสำนักงานตำรวจแห่งชาติ หรือหน่วยงานที่เกี่ยวข้อง เพื่อใช้เป็นส่วนหนึ่งในการพิจารณารับเป็นผู้ขับขี่ของบริษัท',
              style: AppTypography.caption1.copyWith(color: AppColors.semanticGrayNeutralFgHigh),
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.semanticGrayNeutralBorderLightgray),
                borderRadius: BorderRadius.circular(12),
              ),
              child: CheckboxListTile(
                value: _isConsentChecked,
                onChanged: (val) {
                  setState(() {
                    _isConsentChecked = val ?? false;
                  });
                },
                title: Text(
                  'ข้าพเจ้ายินยอมตามเงื่อนไขดังกล่าว',
                  style: AppTypography.subtitle2.copyWith(color: AppColors.semanticGrayNeutralFgHigh),
                ),
                activeColor: AppColors.foundationOrange600,
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
            const Spacer(),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: (_isConsentChecked && !state.isLoading) ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isConsentChecked ? AppColors.foundationOrange600 : AppColors.semanticDisabledBgLow,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: state.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text('ส่งแบบฟอร์มลงทะเบียน', style: AppTypography.subtitle1.copyWith(
                        color: _isConsentChecked ? Colors.white : AppColors.semanticDisabledFgOnWhite)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
