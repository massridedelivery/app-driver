import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/theme/app_palette.dart';
import 'package:massdrive/core/theme/brand_colors.dart';

const _settingsChannel = MethodChannel('massdrive/settings');

/// Android opens Wi-Fi settings directly; iOS can only open the app's own page
/// in Settings, from which Wi-Fi / mobile data are one tap away.
Future<void> openNetworkSettings() async {
  try {
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _settingsChannel.invokeMethod<bool>('openWifiSettings');
    } else {
      await launchUrl(Uri.parse('app-settings:'));
    }
  } catch (_) {
    // Nothing useful to do if the OS refuses; the retry button still works.
  }
}

/// Replaces the home bottom sheet when the driver's data can't be loaded —
/// instead of a skeleton that spins forever. [offline] picks the copy: no
/// internet (with a shortcut to Wi-Fi settings) vs. a load that failed anyway.
class HomeOfflineCard extends StatelessWidget {
  const HomeOfflineCard({
    super.key,
    required this.offline,
    required this.retrying,
    required this.onRetry,
  });

  final bool offline;
  final bool retrying;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final title = offline
        ? 'ไม่มีการเชื่อมต่ออินเทอร์เน็ต'
        : 'โหลดข้อมูลไม่สำเร็จ';
    final body = offline
        ? 'กรุณาเชื่อมต่อ Wi‑Fi หรือเปิดข้อมูลมือถือ\nเพื่อรับงานและดูข้อมูลล่าสุด'
        : 'เกิดข้อผิดพลาดระหว่างโหลดข้อมูล\nกรุณาลองใหม่อีกครั้ง';
    final settingsLabel = defaultTargetPlatform == TargetPlatform.android
        ? 'เปิดการตั้งค่า Wi‑Fi'
        : 'เปิดการตั้งค่า';

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: context.palette.sheet,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: const [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: context.brand.tint,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    offline ? Icons.wifi_off_rounded : Icons.cloud_off_rounded,
                    size: 32,
                    color: context.brand.red,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTypography.heading4.copyWith(
                    color: context.palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: AppTypography.caption4.copyWith(
                    color: context.palette.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: retrying ? null : onRetry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.brand.red,
                      disabledBackgroundColor: context.brand.red
                          .withValues(alpha: 0.5),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                    child: retrying
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'ลองใหม่',
                            style: AppTypography.label1.copyWith(
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                if (offline) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: openNetworkSettings,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: context.palette.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                      ),
                      child: Text(
                        settingsLabel,
                        style: AppTypography.label2.copyWith(
                          color: context.palette.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
