import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:massdrive/core/theme/app_palette.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/features/history_detail/domain/entities/history_entity.dart';
import 'package:massdrive/core/theme/brand_colors.dart';

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
          _buildInfoRow(context, title: "ค่าโดยสาร", value: _money(gross)),
          if (commission != null && commission > 0) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              title: "หักค่าคอมมิชชัน",
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
            // Money is green; "awaiting settlement" is amber.
            color: data.settledNet == null
                ? context.brand.wait
                : context.brand.ok,
          ),
        ),
      ],
    );
  }
}
