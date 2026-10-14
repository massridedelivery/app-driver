import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/theme/app_palette.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/features/history/domain/models/history_item_model.dart';
import 'package:massdrive/core/utils/baht.dart';
import 'package:massdrive/features/history/domain/models/service_icon.dart';

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
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: context.palette.border)),
        ),
        child: Row(
          children: [
            // Service / vehicle icon — the same Mass 3D set as the customer
            // app, shown on its own (no frame).
            SizedBox(
              width: 36,
              height: 36,
              child: Image.asset(
                serviceIconAsset(
                  service: isFood ? 'food' : item.service,
                  vehicleTypeName: item.vehicleTypeName,
                ),
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 12),
            // Time
            Text(
              DateFormat('HH:mm').format(item.dateTime.toLocal()),
              style: AppTypography.caption5.copyWith(color: context.palette.textSecondary),
            ),
            const SizedBox(width: 12),
            // Title
            Expanded(
              child: Text(
                item.title,
                style: AppTypography.caption4.copyWith(
                  color: context.palette.textPrimary,
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
                    formatSignedBaht(item.amount ?? 0),
                    style: AppTypography.caption4.copyWith(
                      color: context.palette.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right, color: context.palette.textTertiary, size: 18),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

