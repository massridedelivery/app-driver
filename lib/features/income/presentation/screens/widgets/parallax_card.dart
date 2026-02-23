import 'package:flutter/material.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_typography.dart';

class ParallaxCard extends StatelessWidget {
  final double today;
  final double week;
  final double offset;
  final double radius;

  const ParallaxCard({
    super.key,
    required this.today,
    required this.week,
    required this.offset,
    this.radius = 24,
  });

  @override
  Widget build(BuildContext context) {
    final scale = (1 - (offset.abs() * 0.08)).clamp(0.92, 1.0);
    final parallax = offset * 50;

    return Transform.translate(
      offset: Offset(parallax, 0),
      child: Transform.scale(
        scale: scale,
        child: Container(
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2F2F2F), Color(0xFF1C1C1C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -30,
                    top: -30,
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.05),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "รายได้วันนี้",
                          style: AppTypography.caption2.copyWith(
                            color: AppColors.semanticGrayNeutralBgWhite,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "฿${today.toStringAsFixed(0)}",
                          style: AppTypography.heading1.copyWith(
                            color: AppColors.semanticGrayNeutralBgWhite,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
