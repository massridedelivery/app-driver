import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/theme/app_palette.dart';
import 'package:massdrive/features/call/presentation/controllers/call_availability.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _primedKey = 'call_permissions_asked';

bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

/// The microphone — plus, on Android 12+, nearby devices so a Bluetooth
/// headset carries the call. True when the microphone is allowed.
Future<bool> requestCallAudioPermissions() async {
  final result = await [
    Permission.microphone,
    if (_isAndroid) Permission.bluetoothConnect,
  ].request();
  return result[Permission.microphone]?.isGranted ?? false;
}

/// Asked once, when the driver goes online: customers call while the phone
/// sits in a mount, locked or under navigation, and answering there needs
/// the microphone granted beforehand — and on Android 14+ the full-screen
/// call permission, or the call is only a notification.
///
/// App Store guideline 5.1.1(iv): the message before the system prompt has a
/// single neutral "ดำเนินการต่อ" button and cannot be dismissed, so the
/// driver always reaches the system permission request (1.0.1 was rejected
/// for an "อนุญาต" / "ไว้ทีหลัง" pair). The choice itself stays with the
/// system dialog.
Future<void> primeCallPermissions(BuildContext context, WidgetRef ref) async {
  if (!ref.read(callAvailabilityProvider).enabled) return;
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool(_primedKey) ?? false) return;

  final micGranted = await Permission.microphone.isGranted;
  final fullScreen =
      !_isAndroid || await FlutterCallkitIncoming.canUseFullScreenIntent();
  if (micGranted && fullScreen) {
    await prefs.setBool(_primedKey, true);
    return;
  }
  if (!context.mounted) return;

  final p = context.palette;
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (d) => PopScope(
      canPop: false,
      child: AlertDialog(
        backgroundColor: p.sheet,
        title: Text(
          'รับสายจากลูกค้าในแอป',
          style: AppTypography.heading6.copyWith(color: p.textPrimary),
        ),
        content: Text(
          fullScreen
              ? 'ลูกค้าโทรหาคุณผ่านแอปได้ระหว่างงาน '
                    'แอปจะขอใช้ไมโครโฟนเพื่อให้คุณคุยกับลูกค้าได้'
              : 'ลูกค้าโทรหาคุณผ่านแอปได้ระหว่างงาน '
                    'แอปจะขอใช้ไมโครโฟนเพื่อให้คุณคุยกับลูกค้าได้ '
                    'และขอแสดงสายเรียกเข้าแบบเต็มหน้าจอ',
          style: AppTypography.body2.copyWith(color: p.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d),
            child: Text(
              'ดำเนินการต่อ',
              style: AppTypography.label2.copyWith(
                color: AppColors.semanticSuccessBgHigh,
              ),
            ),
          ),
        ],
      ),
    ),
  );
  await prefs.setBool(_primedKey, true);
  if (!micGranted) await requestCallAudioPermissions();
  // Opens the system setting (Android 14+).
  if (!fullScreen) await FlutterCallkitIncoming.requestFullIntentPermission();
}
