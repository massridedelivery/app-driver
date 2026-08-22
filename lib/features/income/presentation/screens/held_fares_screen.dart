import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:massdrive/common/widgets/indicator/mass_loading_m.dart';
import 'package:massdrive/common/widgets/appbar/base_appbar.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/theme/app_palette.dart';
import 'package:massdrive/features/income/domain/models/held_fare.dart';
import 'package:massdrive/features/payment/data/payment_api_service.dart';

/// Held fares awaiting finance review — the fares a driver closed via the
/// manual payment-override (SCRUM-86 §D). Endpoint ships in dev15; until then
/// the list simply shows the empty state.
final heldFaresProvider = FutureProvider.autoDispose<List<HeldFare>>(
  (ref) => ref.read(paymentApiServiceProvider).getHeldFares(),
);

class HeldFaresScreen extends ConsumerWidget {
  const HeldFaresScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(heldFaresProvider);
    return Scaffold(
      backgroundColor: context.palette.bg,
      appBar: CommonAppBar(titleText: 'ค่างานรอตรวจสอบ', showLeftIcon: true),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(heldFaresProvider.future),
        child: async.when(
          loading: () => const Center(child: MassLoadingM(size: 64)),
          // The endpoint may not be live yet → treat as empty, don't scare the
          // driver with an error.
          error: (_, __) => _empty(context),
          data: (items) => items.isEmpty
              ? _empty(context)
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _HeldFareCard(item: items[i]),
                ),
        ),
      ),
    );
  }

  Widget _empty(BuildContext context) => ListView(
        children: [
          const SizedBox(height: 120),
          Icon(Icons.receipt_long_outlined,
              size: 64, color: context.palette.textTertiary),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'ยังไม่มีค่างานที่รอตรวจสอบ',
              style: AppTypography.caption3
                  .copyWith(color: context.palette.textSecondary),
            ),
          ),
        ],
      );
}

class _HeldFareCard extends StatelessWidget {
  final HeldFare item;
  const _HeldFareCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '฿${NumberFormat('#,##0').format(item.amount)}',
                style: AppTypography.heading5
                    .copyWith(color: context.palette.textPrimary),
              ),
              _StatusChip(status: item.status),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            item.reason,
            style: AppTypography.caption4
                .copyWith(color: context.palette.textSecondary),
          ),
          if (item.claimedAt != null) ...[
            const SizedBox(height: 4),
            Text(
              DateFormat('d MMM yyyy HH:mm').format(item.claimedAt!),
              style: AppTypography.caption5
                  .copyWith(color: context.palette.textTertiary),
            ),
          ],
          if (item.note != null && item.note!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              item.note!,
              style: AppTypography.caption5
                  .copyWith(color: context.palette.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final HeldFareStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      HeldFareStatus.approved => (
          AppColors.semanticSuccessBgLow,
          AppColors.semanticSuccessBorderHigh,
        ),
      HeldFareStatus.rejected => (
          AppColors.semanticErrorBgHigh.withValues(alpha: 0.15),
          AppColors.semanticErrorBgHigh,
        ),
      HeldFareStatus.pendingReview => (
          context.palette.surfaceAlt,
          context.palette.textSecondary,
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: AppTypography.caption5.copyWith(
          color: fg,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
