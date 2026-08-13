import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:massdrive/common/widgets/appbar/base_appbar.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/services/fcm_debug_log.dart';
import 'package:massdrive/core/services/push_notification_service.dart';

/// On-device FCM diagnostics: current token, permission status, and a log of
/// register/send/receive/tap events — lets a tester check push health without
/// a debugger or device console attached. Reachable from Settings.
class FcmDebugScreen extends StatefulWidget {
  const FcmDebugScreen({super.key});

  @override
  State<FcmDebugScreen> createState() => _FcmDebugScreenState();
}

class _FcmDebugScreenState extends State<FcmDebugScreen> {
  bool _refreshing = false;

  void _copyToken(String token) {
    Clipboard.setData(ClipboardData(text: token));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('คัดลอก FCM token แล้ว')),
    );
  }

  Future<void> _refreshToken() async {
    setState(() => _refreshing = true);
    await PushNotificationService.instance.refreshTokenForDebug();
    if (mounted) setState(() => _refreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    final token = FcmDebugLog.token;
    final permission = FcmDebugLog.permissionStatus;
    final entries = FcmDebugLog.read();

    return Scaffold(
      appBar: CommonAppBar(titleText: 'FCM Debug Log', showLeftIcon: true),
      backgroundColor: AppColors.semanticGrayNeutralFgHigh,
      body: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SectionCard(
              title: 'สิทธิ์แจ้งเตือน',
              child: Text(
                permission ?? '(ยังไม่เคยขอสิทธิ์ในเซสชันนี้)',
                style: AppTypography.body2.copyWith(
                  color: AppColors.semanticGrayNeutralBgWhite,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'FCM Token',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    token ?? '(ยังไม่มี token — Simulator ไม่ได้ token จริง)',
                    style: AppTypography.caption4.copyWith(
                      color: AppColors.semanticGrayNeutralBgWhite,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (token != null)
                        TextButton.icon(
                          onPressed: () => _copyToken(token),
                          icon: const Icon(Icons.copy, size: 16),
                          label: const Text('คัดลอก'),
                        ),
                      TextButton.icon(
                        onPressed: _refreshing ? null : _refreshToken,
                        icon: _refreshing
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.refresh, size: 16),
                        label: const Text('รีเฟรช token'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Log (${entries.length})',
                  style: AppTypography.caption3.copyWith(
                    color: AppColors.semanticGrayNeutralBgWhite,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    FcmDebugLog.clear();
                    setState(() {});
                  },
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('ล้าง log'),
                ),
              ],
            ),
            if (entries.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'ยังไม่มี event — เปิด/ปิดแอปใหม่ หรือลองให้งานเข้าเพื่อสร้าง log',
                  style: AppTypography.caption4.copyWith(
                    color: AppColors.foundationAlphaWhite400,
                  ),
                ),
              )
            else
              ...entries.map((e) => _LogRow(entry: e)),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.caption4.copyWith(
              color: AppColors.foundationAlphaWhite400,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _LogRow extends StatelessWidget {
  final FcmLogEntry entry;

  const _LogRow({required this.entry});

  String _formatTime(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final isError = entry.message.startsWith('ERROR');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formatTime(entry.time),
            style: AppTypography.caption5.copyWith(
              color: AppColors.foundationAlphaWhite400,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              entry.message,
              style: AppTypography.caption4.copyWith(
                color: isError
                    ? AppColors.semanticErrorFgHigh
                    : AppColors.semanticGrayNeutralBgWhite,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
