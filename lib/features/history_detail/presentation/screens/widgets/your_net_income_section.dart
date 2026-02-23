import 'package:flutter/material.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/features/history_detail/domain/entities/history_entity.dart';

class YourNetIncomeSection extends StatelessWidget {
  final HistoryDetailEntity data;

  const YourNetIncomeSection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme),
          const SizedBox(height: 16),
          _buildInfoRow(title: "ค่าบริการ", value: '฿ 30'),
          const SizedBox(height: 12),
          _buildInfoRow(title: "โบนัส", value: "฿ 2"),
          const SizedBox(height: 12),
          _buildInfoRow(title: "หักค่าบริการ", value: "- ฿ 2"),
          const Divider(height: 28),
          _buildTotalRow(theme),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Text(
      "รายได้สุทธิของคุณ",
      style: AppTypography.heading5.copyWith(
        color: AppColors.semanticGrayNeutralFgHigh,
      ),
    );
  }

  Widget _buildInfoRow({required String title, required String value}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppTypography.caption4.copyWith(
            color: AppColors.semanticGrayNeutralFgHigh,
          ),
        ),
        Text(
          value,
          style: AppTypography.caption4.copyWith(
            color: AppColors.semanticGrayNeutralFgHigh,
          ),
        ),
      ],
    );
  }

  Widget _buildTotalRow(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "รวมภาษีแล้ว",
          style: AppTypography.heading5.copyWith(
            color: AppColors.semanticGrayNeutralFgHigh,
          ),
        ),
        Text(
          "฿ ${data.total.toStringAsFixed(0)}",
          style: AppTypography.heading5.copyWith(
            color: AppColors.semanticGrayNeutralFgHigh,
          ),
        ),
      ],
    );
  }
}
