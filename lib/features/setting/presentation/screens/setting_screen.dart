import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:massdrive/common/widgets/appbar/base_appbar.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_routes.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/navigation/app_navigator.dart';
import 'package:massdrive/features/auth/presentation/controllers/auth_controller.dart';
import 'package:massdrive/features/edit_profile/presentation/screens/edit_profile_screen.dart';
import 'package:massdrive/features/profile/presentation/controllers/profile_controller.dart';
import 'package:massdrive/features/review/data/customer_review_api.dart';
import 'package:massdrive/features/setting/presentation/controllers/auto_accept_controller.dart';

class SettingScreen extends ConsumerWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: CommonAppBar(titleText: 'การตั้งค่า', showLeftIcon: true),
      body: Container(
        color: AppColors.semanticGrayNeutralFgHigh,
        child: ListView(
          children: [
            SectionHeader(
              title: "บัญชี",
              textColor: AppColors.semanticGrayNeutralBgWhite,
            ),

            const _AccountTile(),

            const _Divider(),

            SectionHeader(
              title: "การตั้งค่าการให้บริการ",
              textColor: AppColors.semanticGrayNeutralBgWhite,
            ),

            const _AutoAcceptCard(),
            const _Divider(),

            SectionHeader(
              title: "นักพัฒนา",
              textColor: AppColors.semanticGrayNeutralBgWhite,
            ),

            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              leading: const _LeadingIconBadge(
                icon: Icons.bug_report_outlined,
              ),
              title: Text(
                "FCM Debug Log",
                style: AppTypography.caption3.copyWith(
                  color: AppColors.semanticGrayNeutralBgWhite,
                ),
              ),
              subtitle: Text(
                "ดู token / สิทธิ์แจ้งเตือน / log การรับ-ส่ง push",
                style: AppTypography.caption4.copyWith(
                  color: AppColors.foundationAlphaWhite400,
                ),
              ),
              trailing: const Icon(
                Icons.chevron_right,
                color: AppColors.semanticGrayNeutralFgLowOnGray,
              ),
              onTap: () => context.push(AppRoutes.fcmDebugNamedPage),
            ),

            // UI-preview bypass for the driver→customer review screen. The real
            // flow shows it after a completed job; the backend submit is still
            // pending (SCRUM-70), so this opens it with sample data to check UI.
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              leading: const _LeadingIconBadge(
                icon: Icons.star_outline,
              ),
              title: Text(
                "ตัวอย่างหน้ารีวิวลูกค้า",
                style: AppTypography.caption3.copyWith(
                  color: AppColors.semanticGrayNeutralBgWhite,
                ),
              ),
              subtitle: Text(
                "ดู UI หน้าให้คะแนนลูกค้า (โหมดตัวอย่าง — ยังไม่ส่งจริง)",
                style: AppTypography.caption4.copyWith(
                  color: AppColors.foundationAlphaWhite400,
                ),
              ),
              trailing: const Icon(
                Icons.chevron_right,
                color: AppColors.semanticGrayNeutralFgLowOnGray,
              ),
              onTap: () => context.push(
                '/review-customer',
                extra: {
                  'jobId': 'preview',
                  'service': ReviewService.ride,
                  'customerName': 'สมชาย ใจดี',
                  'subtitle': 'ตัวอย่างลูกค้า',
                  'previewMode': true,
                },
              ),
            ),
            const _Divider(),

            SectionHeader(
              title: "ออกจากระบบ",
              textColor: AppColors.semanticErrorBgHigh,
              onTap: () {
                _showLogoutDialog(context, ref);
              },
            ),
          ],
        ),
      ),
    );
  }
}

void _showLogoutDialog(BuildContext parentContext, WidgetRef ref) {
  showDialog(
    context: parentContext,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      title: Text(
        "คุณต้องการออกจากระบบ?",
        style: AppTypography.caption3.copyWith(
          color: AppColors.semanticGrayNeutralBgWhite,
        ),
      ),
      actions: [
        TextButton(
          child: Text(
            "ยกเลิก",
            style: AppTypography.caption3.copyWith(
              color: AppColors.semanticGrayNeutralFgLowOnWhite,
            ),
          ),
          onPressed: () => Navigator.pop(dialogContext),
        ),
        TextButton(
          child: Text(
            "ออกจากระบบ",
            style: AppTypography.caption3.copyWith(
              color: AppColors.semanticErrorFgHigh,
            ),
          ),
          onPressed: () async {
            Navigator.pop(dialogContext); // ปิด popup ก่อน
            await ref.read(authControllerProvider.notifier).logout();

            // The setting screen is opened as an imperative route on top of
            // the go_router stack, so context.go alone leaves it covering the
            // login page. Clear every imperative route first, then go to login.
            if (parentContext.mounted) {
              Navigator.of(
                parentContext,
                rootNavigator: true,
              ).popUntil((route) => route.isFirst);
              AppNavigator.go(parentContext, AppRoutes.loginNamedPage);
            }
          },
        ),
      ],
    ),
  );
}

class SectionHeader extends StatelessWidget {
  final String title;
  final Color? textColor;
  final VoidCallback? onTap;

  const SectionHeader({
    super.key,
    required this.title,
    this.textColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final header = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppTypography.caption3.copyWith(
              color: textColor ?? AppColors.semanticGrayNeutralBgWhite,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return header;

    return InkWell(onTap: onTap, child: header);
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      color: AppColors.semanticGrayNeutralFgMidOnGray,
      height: 1,
    );
  }
}

/// A rounded-square icon chip used as a leading glyph on setting rows/cards,
/// so the screen reads like a modern settings list instead of bare text rows.
class _LeadingIconBadge extends StatelessWidget {
  final IconData icon;
  final Color? background;
  final Color? iconColor;
  final double size;

  const _LeadingIconBadge({
    required this.icon,
    this.background,
    this.iconColor,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background ?? AppColors.foundationAlphaWhite100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        size: size * 0.5,
        color: iconColor ?? AppColors.semanticGrayNeutralBgWhite,
      ),
    );
  }
}

class _AccountTile extends ConsumerWidget {
  const _AccountTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileControllerProvider);
    final profile = profileState.profile;

    if (profile == null) {
      if (!profileState.isLoading) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(profileControllerProvider.notifier).fetchProfile();
        });
      }
      return ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: const _LeadingIconBadge(icon: Icons.person_outline_rounded),
        title: const SizedBox(
          height: 16,
          width: 120,
          child: LinearProgressIndicator(
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white30),
          ),
        ),
        subtitle: const SizedBox(height: 8),
        trailing: const Icon(Icons.chevron_right, color: Colors.white54),
        onTap: () {
          AppNavigator.push(context, const EditProfileScreen());
        },
      );
    }

    final fullName = profile.fullName;
    final phone = profile.phone ?? '';
    final plate = profile.vehiclePlate ?? '';

    final subtitleParts = <String>[];
    if (plate.isNotEmpty) {
      subtitleParts.add(plate);
    }
    if (phone.isNotEmpty) {
      subtitleParts.add(phone);
    }
    final subtitleText = subtitleParts.isNotEmpty
        ? subtitleParts.join(' • ')
        : 'ไม่มีข้อมูลยานพาหนะและเบอร์โทรศัพท์';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: const _LeadingIconBadge(icon: Icons.person_outline_rounded),
      title: Text(
        fullName,
        style: AppTypography.caption3.copyWith(
          color: AppColors.semanticGrayNeutralBgWhite,
        ),
      ),
      subtitle: Text(
        subtitleText,
        style: AppTypography.caption4.copyWith(
          color: AppColors.foundationAlphaWhite400,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.white54),
      onTap: () {
        AppNavigator.push(context, const EditProfileScreen());
      },
    );
  }
}

class _AutoAcceptCard extends ConsumerWidget {
  const _AutoAcceptCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEnabled = ref.watch(autoAcceptProvider);
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0B5E3C),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _LeadingIconBadge(
            icon: Icons.bolt_rounded,
            size: 36,
            background: Colors.white.withOpacity(0.15),
            iconColor: Colors.white,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "รับงานอัตโนมัติ",
                  style: AppTypography.caption3.copyWith(
                    color: AppColors.semanticGrayNeutralBgWhite,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "ระบบจะรับงานให้อัตโนมัติเมื่อหมดเวลานับถอยหลัง",
                  style: AppTypography.caption4.copyWith(
                    color: AppColors.foundationAlphaWhite400,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isEnabled,
            activeThumbColor: Colors.green,
            onChanged: (value) =>
                ref.read(autoAcceptProvider.notifier).setEnabled(value),
          ),
        ],
      ),
    );
  }
}
