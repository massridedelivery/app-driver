import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:massdrive/common/widgets/appbar/base_appbar.dart';
import 'package:massdrive/common/widgets/earnings/job_earnings_card.dart';
import 'package:massdrive/common/widgets/indicator/mass_loading_m.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/constants/endpoints.dart';
import 'package:massdrive/core/navigation/app_navigator.dart';
import 'package:massdrive/core/theme/app_palette.dart';
import 'package:massdrive/core/utils/baht.dart';
import 'package:massdrive/features/wallet/domain/entities/transaction.dart';
import 'package:massdrive/features/wallet/domain/entities/transaction_query.dart';
import 'package:massdrive/features/wallet/domain/enums/transaction_status.dart';
import 'package:massdrive/features/wallet/domain/enums/transaction_type.dart';
import 'package:massdrive/features/wallet/presentation/controllers/transaction_controller.dart';
import 'package:massdrive/features/dependency_injection.dart';
import 'package:massdrive/features/history/domain/models/trip_history_rows.dart';
import 'package:massdrive/features/history_detail/presentation/screens/history_detail_screen.dart';
import 'package:massdrive/features/income/presentation/money_text.dart';
import 'package:massdrive/features/income/presentation/statement_entries.dart';
import 'package:massdrive/features/wallet/presentation/states/transaction_state.dart';

class TransactionHistoryScreen extends ConsumerStatefulWidget {
  final String title;

  /// Optional type filter (e.g. "FARE_PAYMENT" / "payout").
  final String? transactionType;

  /// Job rows only (รายการทั้งหมด), wallet rows only (ประวัติเครดิต) or all.
  final StatementScope scope;

  const TransactionHistoryScreen({
    super.key,
    this.title = 'ประวัติการโอนเงิน',
    this.transactionType,
    this.scope = StatementScope.all,
  });

  @override
  ConsumerState<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState
    extends ConsumerState<TransactionHistoryScreen> {
  late final ScrollController _scrollController;

  /// Vehicle type + backend net per job, for the job cards. Best effort: the
  /// cards fall back to the generic ride icon and "รอสรุปยอด" without it.
  Map<String, TripSummary> _trips = const {};

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    try {
      final res = await getIt<Dio>().get(
        Endpoints.driverEarningsTrips,
        queryParameters: {'limit': 100},
      );
      if (mounted) setState(() => _trips = tripSummariesByJob(res.data));
    } catch (_) {}
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
      backgroundColor: context.palette.bg,
      body: Column(
        children: [
          // ── Total count banner ──────────────────────────────────────
          // The API total counts every row, so only show it unfiltered.
          if (!state.isLoading &&
              state.total > 0 &&
              widget.scope == StatementScope.all)
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: context.palette.surfaceAlt,
              child: Text(
                'ทั้งหมด ${state.total} รายการ',
                style: AppTypography.caption4.copyWith(
                  color: context.palette.textSecondary,
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
                    : _buildScoped(state),
          ),
        ],
      ),
    );
  }

  /// The list for this screen's scope. A page can hold no rows of the scope
  /// (e.g. all top-ups), so read ahead until something shows or the API runs
  /// out.
  Widget _buildScoped(TransactionState state) {
    final items = buildStatement(state.transactions, scope: widget.scope);
    final hasMore = state.transactions.length < state.total;
    if (items.length < 8 && hasMore && !state.isLoadingMore) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(transactionControllerProvider.notifier).loadMore();
      });
    }
    if (items.isEmpty) {
      return state.isLoadingMore || hasMore
          ? const Center(child: MassLoadingM(size: 72))
          : _buildEmptyState();
    }
    return _buildList(items, state.isLoadingMore);
  }

  Widget _buildList(List<StatementEntry> items, bool isLoadingMore) {
    // Statement layout: a date header per day; within a day, every row of the
    // same job (fare, commission) folds into one card with its net.

    return ListView.builder(
      controller: _scrollController,
      // Clear the Android edge-to-edge system nav.
      padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + MediaQuery.viewPaddingOf(context).bottom),
      itemCount: items.length + (isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == items.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: CircularProgressIndicator(),
            ),
          );
        }
        return switch (items[index]) {
          StatementDay(:final date) => EarningsDayHeader(date: date),
          StatementJob job => _JobCard(job: job, trip: _trips[job.jobId]),
          // Hide the divider when the next line isn't another plain row, so
          // groups read as tidy blocks.
          StatementTxn(:final transaction) => _TransactionTile(
            transaction: transaction,
            showDivider:
                index + 1 < items.length && items[index + 1] is StatementTxn,
          ),
        };
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
              color: context.palette.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'โหลดประวัติไม่สำเร็จ',
              style: AppTypography.heading5.copyWith(color: context.palette.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              message.replaceFirst('Exception: ', ''),
              textAlign: TextAlign.center,
              style: AppTypography.caption4.copyWith(
                color: context.palette.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: _load,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: context.palette.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'ลองใหม่',
                style: AppTypography.label2.copyWith(color: context.palette.textPrimary),
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
            color: context.palette.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            switch (widget.scope) {
              StatementScope.jobs => 'ยังไม่มีรายการขับส่ง',
              StatementScope.wallet => 'ยังไม่มีประวัติเครดิต',
              StatementScope.all => 'ไม่มีประวัติการทำรายการ',
            },
            style: AppTypography.caption3.copyWith(
              color: context.palette.textSecondary,
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

  /// Statement rows sit under a shared date header with a hairline between
  /// them; the last row of a day group drops its divider.
  final bool showDivider;

  const _TransactionTile({
    required this.transaction,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.isCredit;
    final amountColor = isCredit
        ? AppColors.semanticSupportMintBgHigh
        : AppColors.semanticErrorFgHigh;
    final time = DateFormat('HH:mm').format(transaction.createdAt.toLocal());
    // Time + optional money breakdown on the sub-line — the day already sits in
    // the header, so the row shows only the clock time.
    final breakdown = transactionBreakdown(transaction);
    final subLine = breakdown == null ? time : '$time · $breakdown';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showDetail(context),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: showDivider
                ? Border(
                    bottom: BorderSide(color: context.palette.border, width: 0.5),
                  )
                : null,
          ),
          child: Row(
            children: [
              // ── Type icon ───────────────────────────────────────────────
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: amountColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _typeIcon(transaction.type),
                  color: amountColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),

              // ── Label + time/breakdown ──────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _typeLabel(transaction.type),
                      style: AppTypography.caption3.copyWith(
                        color: context.palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subLine,
                      style: AppTypography.caption5.copyWith(
                        color: context.palette.textSecondary,
                      ),
                    ),
                    // Job context (SCRUM-105): vertical + pickup→dropoff, when
                    // the backend supplies it for a fare row.
                    if (_jobContext(transaction) case final ctx?) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.place_outlined,
                            size: 12,
                            color: context.palette.textSecondary,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              ctx,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.caption5.copyWith(
                                color: context.palette.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // ── Amount (+ status only when it needs attention) ──────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    transactionAmountText(transaction),
                    style: AppTypography.caption2.copyWith(
                      color: amountColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // A green "สำเร็จ" badge on every row is just noise — surface
                  // the badge only when the status actually needs attention.
                  if (transaction.status != TransactionStatus.completed) ...[
                    const SizedBox(height: 4),
                    _StatusBadge(status: transaction.status),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Thai label for the job's vertical (SCRUM-105). Null for unknown/empty.
  static String? _serviceLabel(String? service) {
    switch (service) {
      case 'ride':
        return 'เรียกรถ';
      case 'food':
        return 'ส่งอาหาร';
      case 'messenger':
        return 'ส่งพัสดุ';
      case 'mart':
        return 'ช้อปปิ้ง';
      default:
        return null;
    }
  }

  /// "pickup → dropoff" from whichever addresses the API supplies. Null when
  /// neither is present (e.g. a top-up/withdrawal row).
  static String? _route(Transaction t) {
    final p = t.pickupAddress?.trim() ?? '';
    final d = t.dropoffAddress?.trim() ?? '';
    if (p.isEmpty && d.isEmpty) return null;
    if (p.isNotEmpty && d.isNotEmpty) return '$p → $d';
    return p.isNotEmpty ? p : d;
  }

  /// One-line job context: "เรียกรถ · ต้นทาง → ปลายทาง". Null when the row has
  /// no service and no route.
  String? _jobContext(Transaction t) {
    final svc = _serviceLabel(t.service);
    final route = _route(t);
    if (svc != null && route != null) return '$svc · $route';
    return route ?? svc;
  }

  /// Opens a bottom sheet with the full transaction breakdown (everything the
  /// API returns for the row — job id, amounts, fees, payment method, dates).
  void _showDetail(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.palette.bg,
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
    const money = formatBaht;
    String date(DateTime d) =>
        DateFormat('d MMM yyyy, HH:mm', 'th_TH').format(d.toLocal());

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
                    color: context.palette.textSecondary,
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
                        color: context.palette.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    transactionAmountText(t),
                    style: AppTypography.heading6.copyWith(
                      color: amountColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _StatusBadge(status: t.status),
              Divider(color: context.palette.border, height: 28),
              // Job id is copyable so a rider can paste it when reporting an
              // issue to support.
              if (t.jobId != null || t.orderId != null)
                _copyableRow(context, 'งาน', t.jobId ?? t.orderId!),
              // Job context (SCRUM-105): vertical + pickup/dropoff addresses.
              if (_serviceLabel(t.service) case final s?)
                _detailRow(context, 'บริการ', s),
              if (t.pickupAddress != null && t.pickupAddress!.trim().isNotEmpty)
                _detailRow(context, 'จุดรับ', t.pickupAddress!.trim()),
              if (t.dropoffAddress != null &&
                  t.dropoffAddress!.trim().isNotEmpty)
                _detailRow(context, 'จุดส่ง', t.dropoffAddress!.trim()),
              if (t.subtotal != null && t.subtotal! > 0)
                _detailRow(context, 'ยอดงาน', money(t.subtotal!)),
              if (t.commission != null && t.commission! > 0)
                _detailRow(context, 'หักค่าคอมมิชชัน', '-${money(t.commission!)}'),
              if (t.platformFee != null && t.platformFee! > 0)
                _detailRow(context, 'ค่าธรรมเนียม', '-${money(t.platformFee!)}'),
              if (t.discount != null && t.discount! > 0)
                _detailRow(context, 'ส่วนลด', money(t.discount!)),
              if (t.paymentMethod != null && t.paymentMethod!.isNotEmpty)
                _detailRow(context, 'วิธีชำระเงิน', t.paymentMethod!),
              // "รายละเอียด" only when it's meaningful — hide the redundant
              // id-echo ("Trip #JOB-…" / "Commission for #JOB-…") that just
              // repeats the job id above. (Pickup/dropoff addresses belong here
              // but the transaction API doesn't return them yet — see BE.)
              if (_showDescription(t.description))
                _detailRow(context, 'รายละเอียด', t.description),
              _detailRow(context, 'วันที่ทำรายการ', date(t.createdAt)),
              if (t.completedAt != null)
                _detailRow(context, 'เสร็จสิ้นเมื่อ', date(t.completedAt!)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(BuildContext context, String label, String value) {
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
                color: context.palette.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
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

  /// A detail row whose value can be tapped to copy (job id, for support).
  Widget _copyableRow(BuildContext context, String label, String value) {
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
                color: context.palette.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('คัดลอกรหัสงานแล้ว'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      value,
                      style: AppTypography.caption4.copyWith(
                        color: context.palette.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.copy_rounded,
                    size: 15,
                    color: context.palette.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Whether the API description is worth its own row. Hides the redundant
  /// id-echo ("Trip #JOB-…", "Commission for #JOB-…") that only repeats the
  /// job id; keeps real notes (e.g. a top-up slip reason).
  bool _showDescription(String description) {
    final s = description.trim();
    if (s.isEmpty) return false;
    final lower = s.toLowerCase();
    // A bare type name ("Topup", "withdrawal"…) only repeats the row title.
    const typeEchoes = {
      'topup',
      'top-up',
      'withdrawal',
      'payout',
      'adjustment',
      'bonus',
      'fare_payment',
      'commission_deduction',
    };
    if (typeEchoes.contains(lower)) return false;
    return !lower.startsWith('trip #') && !lower.startsWith('commission for');
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
      case TransactionType.promoDiscount:
        return Icons.local_offer_rounded;
      case TransactionType.cancellationFeeCollected:
        return Icons.event_busy_rounded;
    }
  }

  static String _typeLabel(TransactionType type) {
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
      case TransactionType.promoDiscount:
        return 'ส่วนลด (บริษัทออกให้)';
      case TransactionType.cancellationFeeCollected:
        return cancellationFeeCollectedLabel;
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

// ─────────────────────────────────────────────────────────────────────────────
// Statement list helpers (date-grouped layout)
// ─────────────────────────────────────────────────────────────────────────────

/// A job's rows as a [JobEarningsCard]; tap opens the trip detail.
class _JobCard extends StatelessWidget {
  final StatementJob job;
  final TripSummary? trip;

  const _JobCard({required this.job, this.trip});

  @override
  Widget build(BuildContext context) => JobEarningsCard(
    jobId: job.jobId,
    time: job.time,
    service: job.service,
    vehicleTypeName: trip?.vehicleTypeName,
    pickupAddress: job.pickupAddress,
    driverNet: trip?.driverNet,
    lines: [
      // The promo row is the company's share of the fare, already counted in
      // the fare and driver_net: listing it as "+฿50" read as extra income.
      for (final t in job.transactions.where(
        (t) => t.type != TransactionType.promoDiscount,
      ))
        JobCardLine(
          label: t.type == TransactionType.commissionDeduction
              ? 'หักค่าคอมมิชชัน'
              : _TransactionTile._typeLabel(t.type),
          amount: t.amount,
          badge: t.status == TransactionStatus.completed
              ? null
              : _StatusBadge(status: t.status),
        ),
    ],
    onTap: () =>
        AppNavigator.push(context, HistoryDetailScreen(jobId: job.jobId)),
  );
}
