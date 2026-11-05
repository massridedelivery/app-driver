import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/theme/app_palette.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/features/history/domain/models/trip_history_rows.dart';
import 'package:massdrive/features/history_detail/domain/entities/history_entity.dart';

class YourNetIncomeSection extends StatelessWidget {
  final HistoryDetailEntity data;

  const YourNetIncomeSection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Whole-baht figures come from the backend only (gross − commission ==
    // net). Until the trip settles they're null and the net shows as pending.
    final gross = data.grossFare ?? data.total.round();
    final commission = data.commission;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, theme),
          const SizedBox(height: 16),
          // ค่าโดยสาร is gross_fare (fare + waiting + toll + other), so
          // ค่าโดยสาร − commission == รายได้สุทธิ. The extras inside it are
          // listed under it; toll and other costs carry no commission.
          _buildInfoRow(context, title: "ค่าโดยสาร", value: _money(gross)),
          for (final (label, amount) in [
            ("ค่ารอ", data.waitingFee),
            ("ค่าทางด่วน", data.tollFee),
            (
              data.otherFeeNote == null
                  ? "ค่าอื่นๆ"
                  : "ค่าอื่นๆ (${data.otherFeeNote})",
              data.otherFee,
            ),
          ])
            if (data.grossFare != null && amount > 0) ...[
              const SizedBox(height: 6),
              _buildIncludedRow(context, label, amount),
            ],
          if (commission != null && commission > 0) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              title: commissionLabel(data.commissionRate),
              value: "- ${_money(commission)}",
            ),
          ],
          const Divider(height: 28),
          _buildTotalRow(context, theme),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Text(
      "รายได้สุทธิของคุณ",
      style: AppTypography.heading5.copyWith(
        color: context.palette.textPrimary,
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required String title,
    required String value,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppTypography.caption4.copyWith(
            color: context.palette.textPrimary,
          ),
        ),
        Text(
          value,
          style: AppTypography.caption4.copyWith(
            color: context.palette.textPrimary,
          ),
        ),
      ],
    );
  }

  /// A part of ค่าโดยสาร: indented, quieter, "รวม…".
  Widget _buildIncludedRow(BuildContext context, String label, num amount) {
    final style = AppTypography.caption5.copyWith(
      color: context.palette.textSecondary,
    );
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: Text("รวม$label", style: style)),
          Text(_money(amount), style: style),
        ],
      ),
    );
  }

  String _money(num value) => '฿${NumberFormat('#,##0').format(value)}';

  Widget _buildTotalRow(BuildContext context, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "รายได้สุทธิ",
          style: AppTypography.heading5.copyWith(
            color: context.palette.textPrimary,
          ),
        ),
        Text(
          data.settledNet == null ? 'รอสรุปยอด' : _money(data.settledNet!),
          style: AppTypography.heading5.copyWith(
            color: AppColors.foundationOrange600,
          ),
        ),
      ],
    );
  }
}
