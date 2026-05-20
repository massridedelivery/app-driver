import 'package:flutter/material.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/features/history_detail/domain/entities/history_entity.dart';

class OrderItemsSection extends StatelessWidget {
  final HistoryDetailEntity data;

  const OrderItemsSection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final items = data.orderItems;
    if (items == null || items.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.semanticGrayNeutralBgWhite,
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
          // Header
          Row(
            children: [
              Icon(
                Icons.receipt_long,
                size: 20,
                color: AppColors.foundationOrange600,
              ),
              const SizedBox(width: 8),
              Text(
                "รายการอาหาร",
                style: AppTypography.heading5.copyWith(
                  color: AppColors.semanticGrayNeutralFgHigh,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Item list
          ...items.map((item) {
            final name = item['name'] ?? '';
            final qty = item['qty'] ?? 1;
            final price = (item['price'] as num?)?.toDouble() ?? 0.0;
            final note = item['note'] as String?;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Qty badge
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.foundationOrange100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${qty}x',
                      style: AppTypography.label3.copyWith(
                        color: AppColors.foundationOrange600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Name & note
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: AppTypography.caption4.copyWith(
                            color: AppColors.semanticGrayNeutralFgHigh,
                          ),
                        ),
                        if (note != null && note.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            note,
                            style: AppTypography.caption5.copyWith(
                              color: AppColors.semanticGrayNeutralFgLowOnWhite,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Price
                  Text(
                    '฿${price.toStringAsFixed(0)}',
                    style: AppTypography.caption4.copyWith(
                      color: AppColors.semanticGrayNeutralFgHigh,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }),

          // Subtotal
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "ค่าอาหาร",
                style: AppTypography.caption4.copyWith(
                  color: AppColors.semanticGrayNeutralFgMidOnGray,
                ),
              ),
              Text(
                "฿${_subtotal.toStringAsFixed(0)}",
                style: AppTypography.caption4.copyWith(
                  color: AppColors.semanticGrayNeutralFgHigh,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double get _subtotal {
    final items = data.orderItems;
    if (items == null) return 0;
    return items.fold<double>(
      0,
      (sum, item) =>
          sum +
          ((item['price'] as num?)?.toDouble() ?? 0) *
              ((item['qty'] as int?) ?? 1),
    );
  }
}
