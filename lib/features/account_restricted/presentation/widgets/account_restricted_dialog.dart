import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:massdrive/core/auth/account_status_notifier.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/constants/support_constants.dart';
import 'package:massdrive/core/theme/app_palette.dart';
import 'package:massdrive/core/theme/brand_colors.dart';

/// Fallback when `/api/config/support` hasn't loaded.
const String fallbackSupportPhone = '065-6924555';

/// The company's driver-support number (from the backend config).
String supportPhone() => SupportConstant.hasCallCenter
    ? SupportConstant.callCenterNumber
    : fallbackSupportPhone;

/// Open the dialer on [supportPhone]. Returns false if it couldn't.
Future<bool> callSupportPhone() async {
  final digits = supportPhone().replaceAll(RegExp(r'[^0-9+]'), '');
  try {
    return await launchUrl(
      Uri.parse('tel:$digits'),
      mode: LaunchMode.externalApplication,
    );
  } catch (_) {
    return false;
  }
}

/// Sign-in refused because the account is suspended: explain and offer a call.
Future<void> showAccountRestrictedDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: dialogContext.palette.surface,
      icon: const Icon(
        Icons.block,
        color: AppColors.foundationRed800,
        size: 40,
      ),
      title: Text(
        'บัญชีถูกระงับการใช้งาน',
        textAlign: TextAlign.center,
        style: AppTypography.heading5.copyWith(
          color: dialogContext.palette.textPrimary,
        ),
      ),
      content: Text(
        '$accountRestrictedLoginMessage\nโทร ${supportPhone()}',
        textAlign: TextAlign.center,
        style: AppTypography.caption3.copyWith(
          color: dialogContext.palette.textSecondary,
          height: 1.5,
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(
            'ปิด',
            style: AppTypography.caption3.copyWith(
              color: dialogContext.palette.textTertiary,
            ),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () async {
            Navigator.pop(dialogContext);
            await callSupportPhone();
          },
          icon: const Icon(Icons.phone, size: 18, color: Colors.white),
          label: Text(
            'โทรหาบริษัท',
            style: AppTypography.caption3.copyWith(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: dialogContext.brand.red,
            elevation: 0,
          ),
        ),
      ],
    ),
  );
}
