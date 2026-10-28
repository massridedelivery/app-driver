import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/theme/app_palette.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/constants/support_constants.dart';
import 'package:massdrive/core/navigation/app_navigator.dart';
import 'package:massdrive/features/call/domain/call_kind.dart';
import 'package:massdrive/features/call/presentation/widgets/call_customer_button.dart';
import 'package:massdrive/features/support/presentation/screens/help_center_screen.dart';

/// Dials the call center. Tells the driver when no number is configured rather
/// than launching a `tel:` URI that goes nowhere.
Future<void> callSupportCenter(BuildContext context) async {
  if (!SupportConstant.hasCallCenter) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ยังไม่ได้ตั้งค่าเบอร์คอลเซ็นเตอร์')),
    );
    return;
  }

  final uri = Uri.parse('tel:${SupportConstant.callCenterDialable}');
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('ไม่สามารถเปิดแอปโทรออกได้')));
  }
}

/// The order whose customer the help sheet can call in-app — for "ลูกค้าไม่มา"
/// and "หาจุดรับไม่เจอ", the usual reasons a driver opens help mid-trip.
class HelpSheetCall {
  const HelpSheetCall({
    required this.kind,
    required this.jobId,
    this.status,
    this.finishedAt,
    this.customerName = '',
  });

  final CallKind kind;
  final String jobId;
  final String? status;
  final DateTime? finishedAt;
  final String customerName;
}

/// In-trip help sheet: call the customer in-app (when [customer] is given and
/// callable), call the center directly, or open the full help center.
Future<void> showHelpSheet(BuildContext context, {HelpSheetCall? customer}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: context.palette.sheet,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.palette.border,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'ช่วยเหลือ',
                  style: AppTypography.heading4.copyWith(
                    color: context.palette.textPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (customer != null)
              CallCustomerButton(
                kind: customer.kind,
                jobId: customer.jobId,
                status: customer.status,
                finishedAt: customer.finishedAt,
                customerName: customer.customerName,
                builder: (_, onCall) => _HelpTile(
                  icon: Icons.phone_in_talk_outlined,
                  title: 'โทรหาลูกค้าในแอป',
                  subtitle: 'ลูกค้าไม่มา หรือหาจุดรับไม่เจอ',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    onCall();
                  },
                ),
              ),
            _HelpTile(
              icon: Icons.call,
              title: 'โทรหาคอลเซ็นเตอร์',
              subtitle: SupportConstant.hasCallCenter
                  ? SupportConstant.callCenterNumber
                  : 'ยังไม่ได้ตั้งค่าเบอร์ติดต่อ',
              onTap: () {
                Navigator.pop(sheetContext);
                callSupportCenter(context);
              },
            ),
            _HelpTile(
              icon: Icons.help_outline,
              title: 'ศูนย์ช่วยเหลือ',
              subtitle: 'คำถามที่พบบ่อยและวิธีแก้ปัญหา',
              onTap: () {
                Navigator.pop(sheetContext);
                AppNavigator.push(context, const HelpCenterScreen());
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      );
    },
  );
}

class _HelpTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _HelpTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: context.palette.surfaceAlt,
        child: Icon(icon, color: AppColors.foundationOrange500),
      ),
      title: Text(
        title,
        style: AppTypography.label2.copyWith(
          color: context.palette.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.caption4.copyWith(
          color: context.palette.textTertiary,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: context.palette.textTertiary),
    );
  }
}
