import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:massdrive/common/widgets/appbar/base_appbar.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_routes.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/navigation/app_navigator.dart';
import 'package:massdrive/features/auth/presentation/controllers/auth_controller.dart';
import 'package:massdrive/features/edit_profile/presentation/screens/edit_profile_screen.dart';

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

            // SectionHeader(
            //   title: "การตั้งค่าการให้บริการ",
            //   textColor: AppColors.semanticGrayNeutralBgWhite,
            //   onTap: () => {},
            // ),

            // const _AutoAcceptCard(),
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
          onPressed: () {
            Navigator.pop(dialogContext); // ปิด popup ก่อน
            ref.read(authControllerProvider.notifier).logout();

            if (parentContext.mounted) {
              AppNavigator.pop(parentContext); // ปิดหน้า setting
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

class _SettingTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? trailingText;

  const _SettingTile({required this.title, this.subtitle, this.trailingText});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            )
          : null,
      trailing: trailingText != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  trailingText!,
                  style: const TextStyle(color: Colors.white54),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, color: Colors.white54),
              ],
            )
          : const Icon(Icons.chevron_right, color: Colors.white54),
    );
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile();

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Text(
        "(MB)ธนนันต์ อนุรักษ์ศิลปกุล",
        style: AppTypography.caption3.copyWith(
          color: AppColors.semanticGrayNeutralBgWhite,
        ),
      ),
      subtitle: Text(
        "8กส418 • +66 892616445",
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

class _AutoAcceptCard extends StatefulWidget {
  const _AutoAcceptCard();

  @override
  State<_AutoAcceptCard> createState() => _AutoAcceptCardState();
}

class _AutoAcceptCardState extends State<_AutoAcceptCard> {
  bool isEnabled = true;

  @override
  Widget build(BuildContext context) {
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
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "รับงานอัตโนมัติ",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              SizedBox(height: 4),
              Text(
                "ระบบจะรับรายการให้โดยอัตโนมัติ",
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ],
          ),
          Switch(
            value: isEnabled,
            activeColor: Colors.green,
            onChanged: (value) {
              setState(() {
                isEnabled = value;
              });
            },
          ),
        ],
      ),
    );
  }
}
