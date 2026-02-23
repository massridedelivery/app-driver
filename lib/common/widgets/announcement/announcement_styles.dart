import 'package:massdrive/common/widgets/announcement/announcement_size.dart';
import 'package:massdrive/common/widgets/announcement/announcement_state.dart';
import 'package:massdrive/common/widgets/announcement/announcement_variant.dart';
import 'package:massdrive/core/constants/app_assets.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_typography.dart';

abstract final class AnnouncementStyle {
  static const info = AnnouncementState(
    bgColor: AppColors.semanticSecondaryBgLowOnWhite,
    borderColor: AppColors.semanticSecondaryBorderLow,
    themeColor: AppColors.semanticSecondaryBorderHigh,
    icon: AppAssets.circleInformationFill,
  );

  static const success = AnnouncementState(
    bgColor: AppColors.semanticSuccessBgLow,
    borderColor: AppColors.semanticSuccessBorderLow,
    themeColor: AppColors.semanticSuccessBorderHigh,
    icon: AppAssets.circleCheckFillIcon,
  );

  static const error = AnnouncementState(
    bgColor: AppColors.semanticErrorBgLowOnWhite,
    borderColor: AppColors.semanticErrorBorderLow,
    themeColor: AppColors.semanticErrorBorderHigh,
    icon: AppAssets.hexagonExclamationFillIcon,
  );

  static const warning = AnnouncementState(
    bgColor: AppColors.semanticWarningBgLowOnWhite,
    borderColor: AppColors.semanticWarningBorderLow,
    themeColor: AppColors.semanticWarningBorderHigh,
    icon: AppAssets.hexagonExclamationFillIcon,
  );
}

abstract final class AnnouncementSizes {
  static const sm = AnnouncementSize(
    titleTextStyle: AppTypography.label3,
    descriptionTextStyle: AppTypography.caption5,
  );

  static const md = AnnouncementSize(
    titleTextStyle: AppTypography.label2,
    descriptionTextStyle: AppTypography.caption5,
  );

  static const lg = AnnouncementSize(
    titleTextStyle: AppTypography.label1,
    descriptionTextStyle: AppTypography.caption4,
  );
}

abstract final class AnnouncementVariants {
  static const inBody = AnnouncementVariant(
    isShowBorder: true,
    isShowShadow: false,
    isFullWidth: false,
  );
  static const inBodyFloat = AnnouncementVariant(
    isShowBorder: true,
    isShowShadow: true,
    isFullWidth: false,
  );
  static const fullWidth = AnnouncementVariant(
    isShowBorder: false,
    isShowShadow: false,
    isFullWidth: true,
  );
  static const fullWidthFloat = AnnouncementVariant(
    isShowBorder: false,
    isShowShadow: true,
    isFullWidth: true,
  );
}
