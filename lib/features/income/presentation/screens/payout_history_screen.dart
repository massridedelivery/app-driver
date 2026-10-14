import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:massdrive/common/widgets/appbar/base_appbar.dart';
import 'package:massdrive/common/widgets/indicator/mass_loading_m.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/theme/app_palette.dart';
import 'package:massdrive/features/income/domain/models/payout.dart';
import 'package:massdrive/features/income/presentation/controllers/wallet_controller.dart';
import 'package:massdrive/core/utils/baht.dart';

/// The driver's withdrawal requests and where each one stands
/// (GET /api/driver/payouts). Refreshes when a `payout_<status>` push arrives.
class PayoutHistoryScreen extends ConsumerStatefulWidget {
  const PayoutHistoryScreen({super.key});

  @override
  ConsumerState<PayoutHistoryScreen> createState() =>
      _PayoutHistoryScreenState();
}

class _PayoutHistoryScreenState extends ConsumerState<PayoutHistoryScreen> {
  late Future<List<PayoutRecord>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
    PayoutUpdates.instance.addListener(_onPayoutChanged);
  }

  @override
  void dispose() {
    PayoutUpdates.instance.removeListener(_onPayoutChanged);
    super.dispose();
  }

  Future<List<PayoutRecord>> _load() =>
      ref.read(walletControllerProvider.notifier).fetchPayoutHistory();

  void _onPayoutChanged() {
    if (!mounted) return;
    setState(() => _future = _load());
    ref.read(walletControllerProvider.notifier).fetchPayoutSummary();
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() => _future = next);
    await next;
  }

  @override
  Widget build(BuildContext context) {
    final limits = ref.watch(walletControllerProvider).payoutLimits;

    return Scaffold(
      backgroundColor: context.palette.bg,
      appBar: CommonAppBar(titleText: 'ประวัติการถอนเงิน', showLeftIcon: true),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<PayoutRecord>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: MassLoadingM(size: 64));
            }
            if (snap.hasError) {
              return _message(
                Icons.wifi_off_rounded,
                'โหลดประวัติการถอนเงินไม่สำเร็จ',
                'ดึงหน้าจอลงเพื่อลองใหม่',
              );
            }
            final items = snap.data ?? const [];
            if (items.isEmpty) {
              return _message(
                Icons.receipt_long_outlined,
                'ยังไม่มีรายการถอนเงิน',
                'คำขอถอนเงินของคุณจะแสดงที่นี่',
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
                  _PayoutCard(record: items[i], limits: limits),
            );
          },
        ),
      ),
    );
  }

  /// Empty / error state that still allows pull-to-refresh.
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

class _PayoutCard extends StatelessWidget {
  const _PayoutCard({required this.record, required this.limits});

  final PayoutRecord record;
  /// The backend's payout record has no net, so the net is worked out with
  /// the backend's own WHT rule.
  final PayoutLimits limits;

  (Color, Color) _statusColors() => switch (record.status) {
    PayoutStatus.completed => (
      AppColors.foundationGreen100,
      AppColors.foundationGreen600,
    ),
    PayoutStatus.rejected || PayoutStatus.failed => (
      AppColors.foundationRed100,
      AppColors.foundationRed800,
    ),
    _ => (AppColors.foundationOrange100, AppColors.foundationOrange600),
  };

  String? _hint() => switch (record.status) {
    PayoutStatus.pending => 'รอบริษัทอนุมัติคำขอ',
    PayoutStatus.approved ||
    PayoutStatus.processing => 'กำลังโอนเข้าบัญชี ปกติภายใน 1–2 วันทำการ',
    PayoutStatus.failed => 'เงินยังอยู่ในยอดที่ถอนได้ของคุณ',
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('d MMM yyyy HH:mm', 'th_TH');
    final (bg, fg) = _statusColors();
    final hint = _hint();
    final reason = record.reason;
    final completed = record.status == PayoutStatus.completed;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  formatBaht(record.amount),
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
                  record.status.label,
                  style: AppTypography.caption4.copyWith(
                    color: fg,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (record.createdAt != null)
            _line(context, 'แจ้งถอน', date.format(record.createdAt!)),
          if (completed && record.processedAt != null)
            _line(context, 'โอนสำเร็จ', date.format(record.processedAt!)),
          if (completed)
            _line(
              context,
              'ได้รับสุทธิ',
              formatBaht(limits.netFor(record.amount)),
            ),
          if (record.bankName != null)
            _line(
              context,
              'เข้าบัญชี',
              [
                record.bankName,
                record.maskedAccount,
              ].whereType<String>().join(' · '),
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
    );
  }

  Widget _line(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 84,
            child: Text(
              label,
              style: AppTypography.caption4.copyWith(
                color: context.palette.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.caption4.copyWith(
                color: context.palette.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
