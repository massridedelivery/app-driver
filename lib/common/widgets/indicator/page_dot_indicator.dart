import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_spacing.dart';

class PageDotIndicator extends ConsumerWidget {
  final int length;
  final int currentPage;

  const PageDotIndicator({
    required this.length,
    required this.currentPage,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.s2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(length, (index) {
          return Container(
            width: AppSpacing.s2,
            height: AppSpacing.s2,
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.s1),
            decoration: BoxDecoration(
              color: currentPage == index
                  ? AppColors.semanticPrimaryFgHigh
                  : AppColors.semanticGrayNeutralBgDarkgray,
              shape: BoxShape.circle,
            ),
          );
        }),
      ),
    );
  }
}
