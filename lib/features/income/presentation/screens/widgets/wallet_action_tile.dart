import 'package:flutter/material.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_spacing.dart';
import 'package:massdrive/core/constants/app_typography.dart';

class WalletActionTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final bool showBadge;
  final String? badgeText;

  const WalletActionTile({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.showBadge = false,
    this.badgeText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s5,
        vertical: AppSpacing.s2,
      ),
      decoration: BoxDecoration(
        color: AppColors.semanticGrayNeutralFgWhite.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.semanticGrayNeutralFgWhite.withOpacity(0.1),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s5),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.s3),
                decoration: BoxDecoration(
                  color: AppColors.semanticGrayNeutralFgWhite.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: AppColors.semanticGrayNeutralBgWhite,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.s5),
              Expanded(
                child: Row(
                  children: [
                    Text(
                      title,
                      style: AppTypography.caption3.copyWith(
                        color: AppColors.semanticGrayNeutralBgWhite,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (showBadge && badgeText != null) ...[
                      const SizedBox(width: AppSpacing.s3),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.foundationRed600,
                              AppColors.foundationRed800,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.foundationRed700.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          badgeText!,
                          style: AppTypography.support1.copyWith(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: AppColors.semanticGrayNeutralBgWhite.withOpacity(0.3),
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
