import 'package:flutter/material.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/features/history/domain/models/history_item_model.dart';

class HistoryItemWidget extends StatelessWidget {
  final HistoryItemModel item;
  final VoidCallback? onTap;

  const HistoryItemWidget({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isFood = item.serviceType == ServiceType.food;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.white12)),
        ),
        child: Row(
          children: [
            // Service type icon
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isFood
                    ? AppColors.foundationOrange600.withOpacity(0.2)
                    : AppColors.semanticPrimaryBgLow.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isFood ? Icons.fastfood : Icons.two_wheeler,
                size: 18,
                color: isFood
                    ? AppColors.foundationOrange500
                    : AppColors.semanticPrimaryBgLow,
              ),
            ),
            const SizedBox(width: 12),
            // Time
            Text(
              "${item.dateTime.hour.toString().padLeft(2, '0')}:${item.dateTime.minute.toString().padLeft(2, '0')}",
              style: AppTypography.caption5.copyWith(color: Colors.white70),
            ),
            const SizedBox(width: 12),
            // Title
            Expanded(
              child: Text(
                item.title,
                style: AppTypography.caption4.copyWith(
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (item.status == HistoryStatus.cancelled)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.semanticSupportRedBgHigh.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  "ยกเลิก",
                  style: AppTypography.caption5.copyWith(
                    color: AppColors.semanticSupportRedBgHigh,
                  ),
                ),
              )
            else
              Row(
                children: [
                  Text(
                    "฿${item.amount?.toStringAsFixed(0) ?? '0'}",
                    style: AppTypography.caption4.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right, color: Colors.white54, size: 18),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

