import 'package:flutter/material.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_typography.dart';

class CompletedTripsTile extends StatelessWidget {
  final int totalTrips;
  final VoidCallback onTap;

  const CompletedTripsTile({
    super.key,
    required this.totalTrips,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "รายการทั้งหมด",
                  style: AppTypography.caption4.copyWith(
                    color: AppColors.semanticGrayNeutralBgWhite,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "$totalTrips รายการ",
                  style: AppTypography.heading4.copyWith(
                    color: AppColors.semanticGrayNeutralBgWhite,
                  ),
                ),
              ],
            ),
            const Icon(Icons.chevron_right, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
