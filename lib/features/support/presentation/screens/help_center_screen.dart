import 'package:flutter/material.dart';
import 'package:massdrive/common/widgets/appbar/base_appbar.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/constants/support_constants.dart';
import 'package:massdrive/features/support/presentation/widgets/support_actions.dart';

/// Driver help center — reachable from the in-trip help sheet and (once wired)
/// the drawer's Help Center entry.
class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  static const _topics = <({IconData icon, String title, String body})>[
    (
      icon: Icons.navigation_outlined,
      title: 'หาจุดรับไม่เจอ',
      body: 'กดปุ่ม "นำทาง" ในหน้างานเพื่อเปิด Google Maps '
          'หากยังหาไม่เจอ ให้ติดต่อลูกค้าผ่านแชทหรือโทรฟรีก่อนโทรหาคอลเซ็นเตอร์',
    ),
    (
      icon: Icons.person_off_outlined,
      title: 'ลูกค้าไม่มารับงาน',
      body: 'รอที่จุดรับตามเวลาที่กำหนด ติดต่อลูกค้าอย่างน้อย 1 ครั้ง '
          'หากติดต่อไม่ได้ ให้แจ้งคอลเซ็นเตอร์เพื่อยกเลิกงานอย่างถูกต้อง '
          'การยกเลิกเองอาจกระทบคะแนนผู้ขับ',
    ),
    (
      icon: Icons.payments_outlined,
      title: 'ปัญหาเรื่องค่าโดยสารหรือการชำระเงิน',
      body: 'ตรวจสอบยอดที่แสดงในหน้างานก่อนจบงาน '
          'หากยอดไม่ตรงหรือลูกค้าไม่ชำระ ให้แจ้งคอลเซ็นเตอร์ทันทีพร้อมหมายเลขงาน',
    ),
    (
      icon: Icons.warning_amber_rounded,
      title: 'อุบัติเหตุหรือเหตุฉุกเฉิน',
      body: 'ความปลอดภัยมาก่อนเสมอ หากมีผู้บาดเจ็บให้โทร 1669 ก่อน '
          'จากนั้นแจ้งคอลเซ็นเตอร์เพื่อบันทึกเหตุการณ์',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.semanticGrayNeutralFgHigh,
      appBar: CommonAppBar(titleText: 'ศูนย์ช่วยเหลือ', showLeftIcon: true),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _CallCenterCard(
              onCall: () => callSupportCenter(context),
            ),
            const SizedBox(height: 20),
            Text(
              'คำถามที่พบบ่อย',
              style: AppTypography.heading5.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            ..._topics.map(
              (t) => _TopicTile(icon: t.icon, title: t.title, body: t.body),
            ),
          ],
        ),
      ),
    );
  }
}

class _CallCenterCard extends StatelessWidget {
  final VoidCallback onCall;

  const _CallCenterCard({required this.onCall});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppColors.semanticGrayNeutralFgMidOnBlack,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ติดต่อคอลเซ็นเตอร์',
            style: AppTypography.heading5.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            SupportConstant.hasCallCenter
                ? SupportConstant.callCenterNumber
                : 'ยังไม่ได้ตั้งค่าเบอร์ติดต่อ',
            style: AppTypography.body2.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: onCall,
              icon: const Icon(Icons.call, color: Colors.white),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.semanticSuccessBgHigh,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              label: Text(
                'โทรหาคอลเซ็นเตอร์',
                style: AppTypography.heading5.copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopicTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _TopicTile({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.semanticGrayNeutralFgMidOnBlack,
      ),
      child: Theme(
        // ExpansionTile draws its own dividers in the light default theme.
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(icon, color: AppColors.foundationOrange500),
          iconColor: Colors.white70,
          collapsedIconColor: Colors.white70,
          title: Text(
            title,
            style: AppTypography.label2.copyWith(color: Colors.white),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              body,
              style: AppTypography.caption3
                  .copyWith(color: Colors.white70, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
