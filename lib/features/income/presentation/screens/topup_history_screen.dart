import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:massdrive/common/widgets/appbar/base_appbar.dart';
import 'package:massdrive/common/widgets/indicator/mass_loading_m.dart';
import 'package:massdrive/core/configs/environment_config.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/data/secure_storage/secure_storage_key.dart';
import 'package:massdrive/core/data/secure_storage/secure_storage_manager.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/theme/app_palette.dart';
import 'package:massdrive/features/income/domain/models/topup.dart';
import 'package:massdrive/features/income/presentation/controllers/wallet_controller.dart';
import 'package:massdrive/core/theme/brand_colors.dart';

/// Bank-transfer (MANUAL) slips the driver sent and their review status
/// (GET /api/driver/settle-debt/requests). Refreshes on a `topup_*` push.
class TopupHistoryScreen extends ConsumerStatefulWidget {
  const TopupHistoryScreen({super.key});

  @override
  ConsumerState<TopupHistoryScreen> createState() => _TopupHistoryScreenState();
}

class _TopupHistoryScreenState extends ConsumerState<TopupHistoryScreen> {
  late Future<List<TopupRequest>> _future;

  /// Slip images are served from the API (`/api/media/files/...`) and need the
  /// driver's token.
  Map<String, String>? _imageHeaders;

  @override
  void initState() {
    super.initState();
    _future = _load();
    SecureStorageManager().read(SecureStorageKey.accessToken).then((t) {
      if (mounted && t != null) {
        setState(() => _imageHeaders = {'Authorization': 'Bearer $t'});
      }
    });
    TopupUpdates.instance.addListener(_onChanged);
  }

  @override
  void dispose() {
    TopupUpdates.instance.removeListener(_onChanged);
    super.dispose();
  }

  Future<List<TopupRequest>> _load() =>
      ref.read(walletControllerProvider.notifier).fetchTopupRequests();

  void _onChanged() {
    if (mounted) setState(() => _future = _load());
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() => _future = next);
    await next;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.bg,
      appBar: CommonAppBar(
        titleText: 'ประวัติการแจ้งโอนเงิน',
        showLeftIcon: true,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<TopupRequest>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: MassLoadingM(size: 64));
            }
            if (snap.hasError) {
              return _message(
                Icons.wifi_off_rounded,
                'โหลดประวัติไม่สำเร็จ',
                'ดึงหน้าจอลงเพื่อลองใหม่',
              );
            }
            final items = snap.data ?? const [];
            if (items.isEmpty) {
              return _message(
                Icons.receipt_long_outlined,
                'ยังไม่มีการแจ้งโอนเงิน',
                'สลิปที่ส่งผ่าน "โอนเงินเข้าบัญชี" จะแสดงที่นี่',
              );
            }
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                16 + MediaQuery.viewPaddingOf(context).bottom,
              ),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, i) =>
                  _TopupCard(request: items[i], imageHeaders: _imageHeaders),
            );
          },
        ),
      ),
    );
  }

  Widget _message(IconData icon, String title, String body) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.22),
        Icon(icon, size: 56, color: context.palette.textTertiary),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppTypography.heading5.copyWith(
            color: context.palette.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          body,
          textAlign: TextAlign.center,
          style: AppTypography.caption4.copyWith(
            color: context.palette.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _TopupCard extends StatelessWidget {
  const _TopupCard({required this.request, this.imageHeaders});

  final TopupRequest request;
  final Map<String, String>? imageHeaders;

  /// The backend returns a path (`/api/media/files/...`); resolve it.
  static String _absolute(String url) =>
      url.startsWith('http') ? url : '${EnvironmentConfig.apiUrl}$url';

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat('#,##0.##');
    final date = DateFormat('d MMM yyyy HH:mm', 'th_TH');
    final (bg, fg) = switch (request.status) {
      TopupRequestStatus.approved => (
        AppColors.foundationGreen100,
        AppColors.foundationGreen600,
      ),
      TopupRequestStatus.rejected => (
        AppColors.foundationRed100,
        AppColors.foundationRed800,
      ),
      // Pending → amber "in review".
      _ => (context.brand.waitBg, context.brand.wait),
    };
    final hint = switch (request.status) {
      TopupRequestStatus.pending => 'อยู่ระหว่างการตรวจสอบโดยผู้ดูแลระบบ',
      TopupRequestStatus.approved => 'หักหนี้ COD ก่อน ส่วนที่เกินเป็นเครดิต',
      TopupRequestStatus.rejected => switch ((
        request.canResubmit(),
        request.intentExpiresAt,
      )) {
        (true, final until?) => 'ส่งสลิปใหม่ได้ถึง ${date.format(until)}',
        (true, null) => 'ส่งสลิปใหม่ได้ภายใน 24 ชั่วโมงหลังเริ่มรายการโอน',
        (false, _) =>
          'รายการโอนนี้หมดอายุแล้ว หากโอนเงินแล้วกรุณาติดต่อฝ่ายบริการลูกค้า',
      },
      TopupRequestStatus.unknown => null,
    };
    final slip = request.slipImageUrl;
    final reason = request.rejectionReason;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.palette.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '฿${money.format(request.amount)}',
                        style: AppTypography.heading4.copyWith(
                          color: context.palette.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        request.status.label,
                        style: AppTypography.caption4.copyWith(
                          color: fg,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (request.createdAt != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'ส่งสลิป ${date.format(request.createdAt!)}',
                    style: AppTypography.caption4.copyWith(
                      color: context.palette.textSecondary,
                    ),
                  ),
                ],
                if (request.status != TopupRequestStatus.pending &&
                    request.processedAt != null)
                  Text(
                    'ตรวจแล้ว ${date.format(request.processedAt!)}',
                    style: AppTypography.caption4.copyWith(
                      color: context.palette.textSecondary,
                    ),
                  ),
                if (reason != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.foundationRed100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'เหตุผล: $reason',
                      style: AppTypography.caption4.copyWith(
                        color: AppColors.foundationRed800,
                      ),
                    ),
                  ),
                ],
                if (hint != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    hint,
                    style: AppTypography.caption5.copyWith(
                      color: context.palette.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (slip != null && imageHeaders != null) ...[
            const SizedBox(width: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                _absolute(slip),
                headers: imageHeaders,
                width: 56,
                height: 72,
                fit: BoxFit.cover,
                // 404 file_not_found (the file was purged), 403 or a bad
                // key: say the image isn't available instead of a broken icon.
                errorBuilder: (_, _, _) => Container(
                  width: 56,
                  height: 72,
                  color: context.palette.surfaceAlt,
                  padding: const EdgeInsets.all(4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_not_supported_outlined,
                        size: 18,
                        color: context.palette.textTertiary,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'รูปไม่พร้อมใช้งาน',
                        textAlign: TextAlign.center,
                        style: AppTypography.caption5.copyWith(
                          color: context.palette.textTertiary,
                          fontSize: 9,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
