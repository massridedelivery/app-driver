import 'package:flutter/material.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/theme/app_palette.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/features/history_detail/domain/entities/history_entity.dart';

class PaymentSection extends StatelessWidget {
  final HistoryDetailEntity data;

  const PaymentSection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
          _buildInfoRow(context, title: "วิธีชำระเงิน", value: data.paymentMethod),
          const SizedBox(height: 12),
          _buildInfoRow(context,
            title: "ระยะทาง",
            value: "${data.distanceKm.toStringAsFixed(2)} km",
          ),
          const SizedBox(height: 12),
          _buildInfoRow(context,
            title: "ระยะเวลา",
            value: "${data.durationMinute} นาที",
          ),
          const Divider(height: 28),
          _buildTotalRow(context, theme),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Text(
      "รายละเอียดการชำระเงิน",
      style: AppTypography.heading5.copyWith(
        color: context.palette.textPrimary,
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, {required String title, required String value}) {
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

  Widget _buildTotalRow(BuildContext context, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "รวม",
          style: AppTypography.heading5.copyWith(
            color: context.palette.textPrimary,
          ),
        ),
        Text(
          "฿ ${data.total.toStringAsFixed(0)}",
          style: AppTypography.heading5.copyWith(
            color: context.palette.textPrimary,
          ),
        ),
      ],
    );
  }
}
