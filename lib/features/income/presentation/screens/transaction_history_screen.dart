import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:massdrive/common/widgets/appbar/base_appbar.dart';
import 'package:massdrive/common/widgets/indicator/mass_loading_m.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/features/wallet/domain/entities/transaction.dart';
import 'package:massdrive/features/wallet/domain/entities/transaction_query.dart';
import 'package:massdrive/features/wallet/domain/enums/transaction_status.dart';
import 'package:massdrive/features/wallet/domain/enums/transaction_type.dart';
import 'package:massdrive/features/wallet/presentation/controllers/transaction_controller.dart';

class TransactionHistoryScreen extends ConsumerStatefulWidget {
  final String title;

  /// Optional type filter (e.g. "FARE_PAYMENT" / "payout").
  final String? transactionType;

  const TransactionHistoryScreen({
    super.key,
    this.title = 'ประวัติการโอนเงิน',
    this.transactionType,
  });

  @override
  ConsumerState<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState
    extends ConsumerState<TransactionHistoryScreen> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    String? mappedType = widget.transactionType;
    if (mappedType == 'payout') {
      mappedType = 'WITHDRAWAL';
    } else if (mappedType == 'topup') {
      mappedType = 'TOPUP';
    }
    ref.read(transactionControllerProvider.notifier).fetchTransactions(
          TransactionQuery(type: mappedType),
        );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(transactionControllerProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transactionControllerProvider);

    return Scaffold(
      appBar: CommonAppBar(
        titleText: widget.title,
        showLeftIcon: true,
      ),
      backgroundColor: AppColors.semanticGrayNeutralFgHigh,
      body: Column(
        children: [
          // ── Total count banner ──────────────────────────────────────
          if (!state.isLoading && state.total > 0)
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppColors.foundationAlphaWhite100,
              child: Text(
                'ทั้งหมด ${state.total} รายการ',
                style: AppTypography.caption4.copyWith(
                  color: AppColors.foundationAlphaWhite400,
                ),
              ),
            ),

          // ── List / Loading / Empty ───────────────────────────────────
          Expanded(
            child: state.isLoading
                ? const Center(child: MassLoadingM(size: 72))
                // A failed fetch is not an empty ledger — saying "no history"
                // when the request errored is as misleading as inventing rows.
                : state.errorMessage.isNotEmpty && state.transactions.isEmpty
                    ? _buildErrorState(state.errorMessage)
                    : state.transactions.isEmpty
                        ? _buildEmptyState()
                        : _buildList(state.transactions, state.isLoadingMore),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<Transaction> transactions, bool isLoadingMore) {
    return ListView.separated(
      controller: _scrollController,
      // Clear the Android edge-to-edge system nav.
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.viewPaddingOf(context).bottom),
      itemCount: transactions.length + (isLoadingMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index == transactions.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: CircularProgressIndicator(),
            ),
          );
        }
        return _TransactionTile(transaction: transactions[index]);
      },
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 64,
              color: AppColors.foundationAlphaWhite400,
            ),
            const SizedBox(height: 16),
            Text(
              'โหลดประวัติไม่สำเร็จ',
              style: AppTypography.heading5.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              message.replaceFirst('Exception: ', ''),
              textAlign: TextAlign.center,
              style: AppTypography.caption4.copyWith(
                color: AppColors.foundationAlphaWhite400,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: _load,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'ลองใหม่',
                style: AppTypography.label2.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: AppColors.foundationAlphaWhite400,
          ),
          const SizedBox(height: 16),
          Text(
            'ไม่มีประวัติการทำรายการ',
            style: AppTypography.caption3.copyWith(
              color: AppColors.foundationAlphaWhite400,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Transaction Tile
// ─────────────────────────────────────────────────────────────────────────────

class _TransactionTile extends StatelessWidget {
  final Transaction transaction;

  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.isCredit;
    final amountColor = isCredit
        ? AppColors.semanticSupportMintBgHigh
        : AppColors.semanticErrorFgHigh;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showDetail(context),
        borderRadius: BorderRadius.circular(12),
        child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.foundationAlphaWhite100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // ── Type icon ─────────────────────────────────────────────────
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: amountColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _typeIcon(transaction.type),
              color: amountColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // ── Description + meta ────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  // Human label (ค่าโดยสาร / ค่าคอมมิชชัน / …) instead of the
                  // raw API description ("Trip #JOB-…"); the job id lives in the
                  // detail sheet.
                  _typeLabel(transaction.type),
                  style: AppTypography.caption3.copyWith(
                    color: AppColors.semanticGrayNeutralBgWhite,
                  ),
                ),
                // Money breakdown so a rider can see what the trip earned vs.
                // what was taken as commission/fees — e.g. "ยอดงาน ฿60 · หักค่าคอม ฿12".
                if (_breakdown(transaction) != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _breakdown(transaction)!,
                    style: AppTypography.caption5.copyWith(
                      color: AppColors.foundationAlphaWhite400,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      DateFormat('d MMM yyyy, HH:mm')
                          .format(transaction.createdAt.toLocal()),
                      style: AppTypography.caption5.copyWith(
                        color: AppColors.foundationAlphaWhite400,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusBadge(status: transaction.status),
                  ],
                ),
              ],
            ),
          ),

          // ── Amount ────────────────────────────────────────────────────
          Text(
            '${isCredit ? '+' : ''}฿${transaction.absoluteAmount.toStringAsFixed(2)}',
            style: AppTypography.caption3.copyWith(
              color: amountColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
        ),
      ),
    );
  }

  /// A one-line earnings breakdown from whatever the API provides, so a rider
  /// can read a fare row without guessing what was deducted. Null when there's
  /// nothing meaningful to show (e.g. a plain top-up/withdrawal).
  String? _breakdown(Transaction t) {
    String money(double v) => '฿${v.toStringAsFixed(0)}';
    final parts = <String>[];
    if (t.subtotal != null && t.subtotal! > 0) {
      parts.add('ยอดงาน ${money(t.subtotal!)}');
    }
    if (t.commission != null && t.commission! > 0) {
      parts.add('หักค่าคอม ${money(t.commission!)}');
    }
    if (t.platformFee != null && t.platformFee! > 0) {
      parts.add('ค่าธรรมเนียม ${money(t.platformFee!)}');
    }
    return parts.isEmpty ? null : parts.join(' · ');
  }

  /// Opens a bottom sheet with the full transaction breakdown (everything the
  /// API returns for the row — job id, amounts, fees, payment method, dates).
  void _showDetail(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.semanticGrayNeutralFgHigh,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => _buildDetailSheet(sheetContext),
    );
  }

  Widget _buildDetailSheet(BuildContext context) {
    final t = transaction;
    final isCredit = t.isCredit;
    final amountColor = isCredit
        ? AppColors.semanticSupportMintBgHigh
        : AppColors.semanticErrorFgHigh;
    String money(double v) => '฿${v.toStringAsFixed(2)}';
    String date(DateTime d) =>
        DateFormat('d MMM yyyy, HH:mm').format(d.toLocal());

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: 20 + MediaQuery.of(context).viewPadding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.foundationAlphaWhite400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: amountColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_typeIcon(t.type), color: amountColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _typeLabel(t.type),
                      style: AppTypography.heading6.copyWith(
                        color: AppColors.semanticGrayNeutralBgWhite,
                      ),
                    ),
                  ),
                  Text(
                    '${isCredit ? '+' : ''}${money(t.absoluteAmount)}',
                    style: AppTypography.heading6.copyWith(
                      color: amountColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _StatusBadge(status: t.status),
              const Divider(color: Colors.white12, height: 28),
              if (t.jobId != null || t.orderId != null)
                _detailRow('งาน', t.jobId ?? t.orderId!),
              if (t.subtotal != null && t.subtotal! > 0)
                _detailRow('ยอดงาน', money(t.subtotal!)),
              if (t.commission != null && t.commission! > 0)
                _detailRow('หักค่าคอมมิชชัน', '-${money(t.commission!)}'),
              if (t.platformFee != null && t.platformFee! > 0)
                _detailRow('ค่าธรรมเนียม', '-${money(t.platformFee!)}'),
              if (t.discount != null && t.discount! > 0)
                _detailRow('ส่วนลด', money(t.discount!)),
              if (t.paymentMethod != null && t.paymentMethod!.isNotEmpty)
                _detailRow('วิธีชำระเงิน', t.paymentMethod!),
              _detailRow('รายละเอียด', t.description),
              _detailRow('วันที่ทำรายการ', date(t.createdAt)),
              if (t.completedAt != null)
                _detailRow('เสร็จสิ้นเมื่อ', date(t.completedAt!)),
              _detailRow('รหัสรายการ', t.id),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTypography.caption5.copyWith(
                color: AppColors.foundationAlphaWhite400,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: AppTypography.caption4.copyWith(
                color: AppColors.semanticGrayNeutralBgWhite,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _typeIcon(TransactionType type) {
    switch (type) {
      case TransactionType.farePayment:
        return Icons.directions_car_rounded;
      case TransactionType.commissionDeduction:
        return Icons.percent_rounded;
      case TransactionType.topup:
        return Icons.add_card_rounded;
      case TransactionType.withdrawal:
        return Icons.account_balance_rounded;
      case TransactionType.bonus:
        return Icons.star_rounded;
      case TransactionType.adjustment:
        return Icons.tune_rounded;
    }
  }

  String _typeLabel(TransactionType type) {
    switch (type) {
      case TransactionType.farePayment:
        return 'ค่าโดยสาร';
      case TransactionType.commissionDeduction:
        return 'ค่าคอมมิชชัน';
      case TransactionType.topup:
        return 'เติมเงิน';
      case TransactionType.withdrawal:
        return 'ถอนเงิน';
      case TransactionType.bonus:
        return 'โบนัส';
      case TransactionType.adjustment:
        return 'ปรับยอด';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status badge widget
// ─────────────────────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final TransactionStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      TransactionStatus.completed => (
          AppColors.semanticSupportMintBgHigh,
          'สำเร็จ'
        ),
      TransactionStatus.pending => (
          AppColors.semanticWarningBorderHigh,
          'รอดำเนินการ'
        ),
      TransactionStatus.failed => (AppColors.semanticErrorFgHigh, 'ล้มเหลว'),
      TransactionStatus.rejected => (
          AppColors.semanticErrorFgHigh,
          'ถูกปฏิเสธ'
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: AppTypography.caption5.copyWith(color: color),
      ),
    );
  }
}
