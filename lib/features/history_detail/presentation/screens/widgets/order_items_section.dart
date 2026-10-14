import 'package:flutter/material.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/theme/app_palette.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/features/history_detail/domain/entities/history_entity.dart';
import 'package:massdrive/core/utils/baht.dart';
import 'package:massdrive/features/incoming_job/domain/models/food_order_lines.dart';

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
                  color: context.palette.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Item list
          ...FoodOrderLine.listFrom(items).map((line) {
            final name = line.name;
            final qty = line.qty;
            final note = line.note;

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
                            color: context.palette.textPrimary,
                          ),
                        ),
                        if (note != null && note.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            note,
                            style: AppTypography.caption5.copyWith(
                              color: context.palette.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Price
                  Text(
                    formatBaht(line.lineTotal),
                    style: AppTypography.caption4.copyWith(
                      color: context.palette.textPrimary,
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
                  color: context.palette.textSecondary,
                ),
              ),
              Text(
                formatBaht(
                  FoodOrderTotals.from(
                    lines: FoodOrderLine.listFrom(items),
                  ).itemsSubtotal,
                ),
                style: AppTypography.caption4.copyWith(
                  color: context.palette.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
