import 'package:flutter/material.dart';
import 'package:massdrive/common/widgets/badge/models/badge_size.dart';
import 'package:massdrive/core/constants/app_spacing.dart';
import 'package:massdrive/core/constants/app_typography.dart';

class BadgeSizes {
  static const lg = BadgeSizeState(
    normal: BadgeSize(
      textStyle: AppTypography.caption3,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.s3,
        vertical: AppSpacing.s1,
      ),
      cornerRadius: AppSpacing.rounded6,
      iconSize: AppSpacing.s5,
      iconPadding: AppSpacing.s3,
    ),
    bold: BadgeSize(
      textStyle: AppTypography.label1,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.s3,
        vertical: AppSpacing.s1,
      ),
      cornerRadius: AppSpacing.rounded6,
      iconSize: AppSpacing.s5,
      iconPadding: AppSpacing.s3,
    ),
  );

  static const md = BadgeSizeState(
    normal: BadgeSize(
      textStyle: AppTypography.caption4,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.s3,
        vertical: AppSpacing.s1,
      ),
      cornerRadius: AppSpacing.rounded5,
    ),
    bold: BadgeSize(
      textStyle: AppTypography.label2,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.s3,
        vertical: AppSpacing.s1,
      ),
      cornerRadius: AppSpacing.rounded5,
    ),
  );

  static const sm = BadgeSizeState(
    normal: BadgeSize(
      textStyle: AppTypography.caption5,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.s3,
        vertical: AppSpacing.s1,
      ),
      cornerRadius: AppSpacing.rounded4,
    ),
    bold: BadgeSize(
      textStyle: AppTypography.label3,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.s3,
        vertical: AppSpacing.s1,
      ),
      cornerRadius: AppSpacing.rounded4,
    ),
  );

  static const xs = BadgeSizeState(
    normal: BadgeSize(
      textStyle: AppTypography.support2,
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.s2, vertical: 1),
      cornerRadius: AppSpacing.rounded4,
    ),
    bold: BadgeSize(
      textStyle: AppTypography.support1,
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.s2, vertical: 1),
      cornerRadius: AppSpacing.rounded4,
    ),
  );
}
