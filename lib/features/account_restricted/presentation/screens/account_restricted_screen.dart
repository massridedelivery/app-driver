import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:massdrive/core/auth/account_status_notifier.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_routes.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/constants/endpoints.dart';
import 'package:massdrive/core/constants/support_constants.dart';
import 'package:massdrive/core/theme/app_palette.dart';
import 'package:massdrive/features/dependency_injection.dart';

/// Shown instead of the app when the driver's account was deleted or
/// suspended. The router keeps the driver here (settings is the only other
/// reachable screen, and it only offers logout) until the restriction clears.
class AccountRestrictedScreen extends StatefulWidget {
  const AccountRestrictedScreen({super.key});

  /// Used when the support config hasn't loaded.
  static const fallbackSupportPhone = '065-6924555';

  @override
  State<AccountRestrictedScreen> createState() =>
      _AccountRestrictedScreenState();
}

class _AccountRestrictedScreenState extends State<AccountRestrictedScreen> {
  bool _checking = false;

  String get _phone => SupportConstant.hasCallCenter
      ? SupportConstant.callCenterNumber
      : AccountRestrictedScreen.fallbackSupportPhone;

  Future<void> _call() async {
    final digits = _phone.replaceAll(RegExp(r'[^0-9+]'), '');
    try {
      await launchUrl(
        Uri.parse('tel:$digits'),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่สามารถเปิดแอปโทรออกได้')),
      );
    }
  }

  /// Re-read the profile: if the company has restored the account, clearing
  /// the flag lets the router send the driver back to home.
  Future<void> _recheck() async {
    setState(() => _checking = true);
    try {
      final res = await getIt<Dio>().get(Endpoints.driverProfile);
      final still = detectAccountRestriction(
        statusCode: res.statusCode,
        data: res.data,
        isProfileEndpoint: true,
      );
      if (still == null) {
        AccountStatusNotifier.instance.clear();
        return;
      }
    } catch (_) {
      // 404/403 again (the interceptor keeps the flag) or offline.
    }
    if (!mounted) return;
    setState(() => _checking = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('บัญชียังไม่สามารถใช้งานได้ กรุณาติดต่อบริษัท'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final deleted =
        AccountStatusNotifier.instance.restriction ==
        AccountRestriction.deleted;
    final title = deleted ? 'บัญชีนี้ถูกลบแล้ว' : 'บัญชีถูกระงับการใช้งาน';
    final body = deleted
        ? 'บัญชีคนขับของคุณถูกลบออกจากระบบ\nกรุณาติดต่อบริษัทเพื่อสอบถามรายละเอียด'
        : 'บัญชีคนขับของคุณถูกระงับการใช้งานชั่วคราว\nกรุณาติดต่อบริษัทเพื่อสอบถามรายละเอียด';

    return Scaffold(
      backgroundColor: context.palette.bg,
      appBar: AppBar(
        backgroundColor: context.palette.bg,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'การตั้งค่า',
            icon: Icon(
              Icons.settings_outlined,
              color: context.palette.textPrimary,
            ),
            onPressed: () => context.push(AppRoutes.settingNamedPage),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  color: AppColors.foundationRed100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  deleted ? Icons.person_off_outlined : Icons.block,
                  size: 48,
                  color: AppColors.foundationRed800,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTypography.heading3.copyWith(
                  color: context.palette.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                body,
                textAlign: TextAlign.center,
                style: AppTypography.caption3.copyWith(
                  color: context.palette.textSecondary,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'ฝ่ายบริการคนขับ $_phone',
                textAlign: TextAlign.center,
                style: AppTypography.label2.copyWith(
                  color: context.palette.textPrimary,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _call,
                  icon: const Icon(Icons.phone, color: Colors.white),
                  label: Text(
                    'โทรหาบริษัท',
                    style: AppTypography.label1.copyWith(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.foundationOrange600,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _checking ? null : _recheck,
                child: _checking
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        'ตรวจสอบสถานะอีกครั้ง',
                        style: AppTypography.caption3.copyWith(
                          color: context.palette.textSecondary,
                          decoration: TextDecoration.underline,
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
