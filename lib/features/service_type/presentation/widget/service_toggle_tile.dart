import 'package:flutter/material.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_typography.dart';

class ServiceToggleTile extends StatelessWidget {
  final String title;
  final bool isEnabled;
  final VoidCallback onToggle;

  const ServiceToggleTile({
    super.key,
    required this.title,
    required this.isEnabled,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: AppTypography.caption2.copyWith(
                color: isEnabled
                    ? AppColors.semanticGrayNeutralBgWhite
                    : AppColors.semanticGrayNeutralBgWhite.withOpacity(0.4),
                fontWeight: isEnabled ? FontWeight.w600 : FontWeight.w400,
              ),
              child: Text(title),
            ),

            _AnimatedToggle(isEnabled: isEnabled),
          ],
        ),
      ),
    );
  }
}

class _AnimatedToggle extends StatelessWidget {
  final bool isEnabled;

  const _AnimatedToggle({required this.isEnabled});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 50,
      height: 26,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isEnabled
            ? AppColors.foundationOrange600
            : AppColors.semanticGrayNeutralFgMidOnWhite,
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        alignment: isEnabled ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.semanticGrayNeutralBgWhite,
          ),
        ),
      ),
    );
  }
}
