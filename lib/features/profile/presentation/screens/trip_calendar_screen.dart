import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:massdrive/common/widgets/appbar/base_appbar.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/theme/app_palette.dart';
import 'package:massdrive/features/dependency_injection.dart';
import 'package:massdrive/features/wallet/domain/entities/transaction.dart';
import 'package:massdrive/features/wallet/domain/entities/transaction_query.dart';
import 'package:massdrive/features/wallet/domain/usecases/get_transaction_list_usecase.dart';
import 'package:massdrive/features/wallet/domain/usecases/get_wallet_overview_usecase.dart';

/// Trip calendar (Grab-style): pick a day or a week and see the net earnings,
/// completed-trip count and trip list for that range. All data comes from the
/// existing ranged endpoints — GET /api/driver/earnings and
/// /api/driver/earnings/transactions (both take start_date/end_date).
class TripCalendarScreen extends ConsumerStatefulWidget {
  const TripCalendarScreen({super.key});

  @override
  ConsumerState<TripCalendarScreen> createState() => _TripCalendarScreenState();
}

class _TripCalendarScreenState extends ConsumerState<TripCalendarScreen> {
  bool _weekly = false;

  /// The selected day (day mode) or any day inside the selected week (week mode).
  late DateTime _anchor;

  bool _loading = true;
  double _netEarnings = 0;
  List<Transaction> _trips = const [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _anchor = DateTime(now.year, now.month, now.day);
    _load();
  }

  // ── date helpers ────────────────────────────────────────────────────────
  static String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  DateTime _mondayOf(DateTime d) =>
      DateTime(d.year, d.month, d.day).subtract(Duration(days: d.weekday - 1));

  (DateTime, DateTime) get _range {
    if (_weekly) {
      final start = _mondayOf(_anchor);
      return (start, start.add(const Duration(days: 6)));
    }
    return (_anchor, _anchor);
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final (start, end) = _range;
    try {
      final overview = await getIt<GetWalletOverviewUseCase>()
          .execute(startDate: _ymd(start), endDate: _ymd(end));
      final result = await getIt<GetTransactionListUseCase>().execute(
        TransactionQuery(
          startDate: _ymd(start),
          endDate: _ymd(end),
          type: 'FARE_PAYMENT',
          limit: 100,
        ),
      );
      if (!mounted) return;
      setState(() {
        _netEarnings = overview.earnings;
        _trips = result.transactions;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _netEarnings = 0;
        _trips = const [];
        _loading = false;
      });
    }
  }

  void _select(DateTime day) {
    setState(() => _anchor = day);
    _load();
  }

  void _setMode(bool weekly) {
    if (weekly == _weekly) return;
    setState(() => _weekly = weekly);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.bg,
      appBar: CommonAppBar(titleText: 'ตารางการขับขี่', showLeftIcon: true),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            _modeToggle(),
            const SizedBox(height: 12),
            _weekly ? _weekStrip() : _dayStrip(),
            Divider(color: context.palette.border, height: 24),
            _summary(),
            const SizedBox(height: 8),
            Expanded(child: _list()),
          ],
        ),
      ),
    );
  }

  // ── mode toggle ─────────────────────────────────────────────────────────
  Widget _modeToggle() {
    Widget seg(String label, bool weekly) {
      final active = _weekly == weekly;
      return GestureDetector(
        onTap: () => _setMode(weekly),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: active
                ? AppColors.semanticSuccessBgHigh.withValues(alpha: 0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: AppTypography.caption4.copyWith(
              color: active
                  ? AppColors.semanticSuccessBgHigh
                  : context.palette.textSecondary,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [seg('รายวัน', false), const SizedBox(width: 8), seg('รายสัปดาห์', true)],
      ),
    );
  }

  // ── day strip: last 30 days, newest on the right ────────────────────────
  Widget _dayStrip() {
    final today = DateTime.now();
    final base = DateTime(today.year, today.month, today.day);
    const days = 30;
    return SizedBox(
      height: 72,
      child: ListView.builder(
        reverse: true,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: days,
        itemBuilder: (context, i) {
          final day = base.subtract(Duration(days: i));
          final selected = _sameDay(day, _anchor) && !_weekly;
          return _dateChip(
            top: DateFormat('E', 'th').format(day),
            bottom: DateFormat('d').format(day),
            selected: selected,
            onTap: () => _select(day),
          );
        },
      ),
    );
  }

  // ── week strip: last 10 weeks ───────────────────────────────────────────
  Widget _weekStrip() {
    final thisMonday = _mondayOf(DateTime.now());
    const weeks = 10;
    return SizedBox(
      height: 72,
      child: ListView.builder(
        reverse: true,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: weeks,
        itemBuilder: (context, i) {
          final monday = thisMonday.subtract(Duration(days: 7 * i));
          final sunday = monday.add(const Duration(days: 6));
          final selected = _weekly && _sameDay(_mondayOf(_anchor), monday);
          return _dateChip(
            top: 'สัปดาห์',
            bottom: '${DateFormat('d/M').format(monday)}-${DateFormat('d/M').format(sunday)}',
            selected: selected,
            wide: true,
            onTap: () => _select(monday),
          );
        },
      ),
    );
  }

  Widget _dateChip({
    required String top,
    required String bottom,
    required bool selected,
    required VoidCallback onTap,
    bool wide = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: wide ? 96 : 56,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.semanticSuccessBgHigh
              : context.palette.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              top,
              style: AppTypography.caption5.copyWith(
                color: selected ? Colors.white : context.palette.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              bottom,
              style: AppTypography.caption3.copyWith(
                color: selected
                    ? Colors.white
                    : context.palette.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── summary: net earnings + completed count ─────────────────────────────
  Widget _summary() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'รายได้สุทธิของคุณ',
            style: AppTypography.caption4.copyWith(color: context.palette.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            '฿${_loading ? '—' : _netEarnings.toStringAsFixed(0)}',
            style: AppTypography.heading2.copyWith(
              color: context.palette.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${_loading ? '—' : _trips.length} งานที่ทำสำเร็จ',
            style: AppTypography.caption4.copyWith(
              color: AppColors.foundationOrange500,
            ),
          ),
        ],
      ),
    );
  }

  // ── trip list ───────────────────────────────────────────────────────────
  Widget _list() {
    if (_loading) {
      return const Center(
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (_trips.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.no_transfer_rounded, color: context.palette.border, size: 48),
            const SizedBox(height: 12),
            Text(
              _weekly ? 'ไม่มีกิจกรรมในสัปดาห์นี้' : 'ไม่มีงานในวันนี้',
              style: AppTypography.caption4.copyWith(color: context.palette.textSecondary),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _trips.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) => _tripTile(_trips[i]),
    );
  }

  Widget _tripTile(Transaction t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.palette.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.semanticSuccessBgHigh.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.directions_car_rounded,
              color: AppColors.semanticSuccessBgHigh,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ค่าโดยสาร',
                  style: AppTypography.caption4.copyWith(
                    color: context.palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('d MMM, HH:mm', 'th').format(t.createdAt.toLocal()),
                  style: AppTypography.caption5.copyWith(color: context.palette.textSecondary),
                ),
              ],
            ),
          ),
          Text(
            '+฿${t.absoluteAmount.toStringAsFixed(0)}',
            style: AppTypography.caption3.copyWith(
              color: AppColors.semanticSupportMintBgHigh,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
