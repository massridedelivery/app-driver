import 'package:flutter/material.dart';
import 'package:massdrive/common/widgets/badge/models/badge_color.dart';
import 'package:massdrive/core/constants/app_colors.dart';

class BadgeColors {
  static const red = BadgeColorState(
    high: BadgeColor(
      backgroundColor: AppColors.semanticSupportRedBgHigh,
      textColor: AppColors.semanticGrayNeutralFgWhite,
    ),
    mid: BadgeColor(
      backgroundColor: AppColors.semanticSupportRedBgLow,
      textColor: AppColors.semanticSupportRedFgOnLow,
    ),
    low: BadgeColor(
      backgroundColor: AppColors.semanticSupportRedBgLowest,
      textColor: AppColors.semanticSupportRedFgOnLow,
      borderColor: AppColors.semanticSupportRedBorderOnWhite,
    ),
  );

  static const orange = BadgeColorState(
    high: BadgeColor(
      backgroundColor: AppColors.semanticSupportOrangeBgHigh,
      textColor: AppColors.semanticGrayNeutralFgWhite,
    ),
    mid: BadgeColor(
      backgroundColor: AppColors.semanticSupportOrangeBgLow,
      textColor: AppColors.semanticSupportOrangeFgOnLow,
    ),
    low: BadgeColor(
      backgroundColor: AppColors.semanticSupportOrangeBgLowest,
      textColor: AppColors.semanticSupportOrangeFgOnLow,
      borderColor: AppColors.semanticSupportOrangeBorderOnWhite,
    ),
  );

  static const yellow = BadgeColorState(
    high: BadgeColor(
      backgroundColor: AppColors.semanticSupportYellowBgHigh,
      textColor: AppColors.semanticGrayNeutralFgWhite,
    ),
    mid: BadgeColor(
      backgroundColor: AppColors.semanticSupportYellowBgLow,
      textColor: AppColors.semanticSupportYellowFgOnLow,
    ),
    low: BadgeColor(
      backgroundColor: AppColors.semanticSupportYellowBgLowest,
      textColor: AppColors.semanticSupportYellowFgOnLow,
      borderColor: AppColors.semanticSupportYellowBorderOnWhite,
    ),
  );

  static const green = BadgeColorState(
    high: BadgeColor(
      backgroundColor: AppColors.semanticSupportMintBgHigh,
      textColor: AppColors.semanticGrayNeutralFgWhite,
    ),
    mid: BadgeColor(
      backgroundColor: AppColors.semanticSupportMintBgLow,
      textColor: AppColors.semanticSupportMintFgOnLow,
    ),
    low: BadgeColor(
      backgroundColor: AppColors.semanticSupportMintBgLowest,
      textColor: AppColors.semanticSupportMintFgOnLow,
      borderColor: AppColors.semanticSupportMintBorderOnWhite,
    ),
  );

  static const cyan = BadgeColorState(
    high: BadgeColor(
      backgroundColor: AppColors.semanticSupportCapriBgHigh,
      textColor: AppColors.semanticGrayNeutralFgWhite,
    ),
    mid: BadgeColor(
      backgroundColor: AppColors.semanticSupportCapriBgLow,
      textColor: AppColors.semanticSupportCapriFgOnLow,
    ),
    low: BadgeColor(
      backgroundColor: AppColors.semanticSupportCapriBgLowest,
      textColor: AppColors.semanticSupportCapriFgOnLow,
      borderColor: AppColors.semanticSupportCapriBorderOnWhite,
    ),
  );

  static const blue = BadgeColorState(
    high: BadgeColor(
      backgroundColor: AppColors.semanticSupportBlueBgHigh,
      textColor: AppColors.semanticGrayNeutralFgWhite,
    ),
    mid: BadgeColor(
      backgroundColor: AppColors.semanticSupportBlueBgLow,
      textColor: AppColors.semanticSupportBlueFgOnLow,
    ),
    low: BadgeColor(
      backgroundColor: AppColors.semanticSupportBlueBgLowest,
      textColor: AppColors.semanticSupportBlueFgOnLow,
      borderColor: AppColors.semanticSupportBlueBorderOnWhite,
    ),
  );

  static const purple = BadgeColorState(
    high: BadgeColor(
      backgroundColor: AppColors.semanticSupportVioletBgHigh,
      textColor: AppColors.semanticGrayNeutralFgWhite,
    ),
    mid: BadgeColor(
      backgroundColor: AppColors.semanticSupportVioletBgLow,
      textColor: AppColors.semanticSupportVioletFgOnLow,
    ),
    low: BadgeColor(
      backgroundColor: AppColors.semanticSupportVioletBgLowest,
      textColor: AppColors.semanticSupportVioletFgOnLow,
      borderColor: AppColors.semanticSupportVioletBorderOnWhite,
    ),
  );

  static const pink = BadgeColorState(
    high: BadgeColor(
      backgroundColor: AppColors.semanticSupportPinkBgHigh,
      textColor: AppColors.semanticGrayNeutralFgWhite,
    ),
    mid: BadgeColor(
      backgroundColor: AppColors.semanticSupportPinkBgLow,
      textColor: AppColors.semanticSupportPinkFgOnLow,
    ),
    low: BadgeColor(
      backgroundColor: AppColors.semanticSupportPinkBgLowest,
      textColor: AppColors.semanticSupportPinkFgOnLow,
      borderColor: AppColors.semanticSupportPinkBorderOnWhite,
    ),
  );

  static const gray = BadgeColorState(
    high: BadgeColor(
      backgroundColor: AppColors.semanticSupportGrayBgMid,
      textColor: AppColors.semanticGrayNeutralFgHigh,
    ),
    mid: BadgeColor(
      backgroundColor: AppColors.semanticGrayNeutralBgMidgray,
      textColor: AppColors.semanticSupportGrayFgOnLow,
    ),
    low: BadgeColor(
      backgroundColor: AppColors.semanticGrayNeutralBgWhite,
      textColor: AppColors.semanticSupportGrayFgOnLow,
      borderColor: AppColors.semanticSupportGrayBorderOnWhite,
    ),
  );

  static const alpha = BadgeColorState(
    high: BadgeColor(
      backgroundColor: AppColors.semanticAlphaBlackBgMid,
      textColor: AppColors.semanticGrayNeutralFgWhite,
    ),
    mid: BadgeColor(
      backgroundColor: Colors.transparent,
      textColor: Colors.transparent,
    ),
    low: BadgeColor(
      backgroundColor: AppColors.semanticAlphaBlackBgLow,
      textColor: AppColors.semanticGrayNeutralFgWhite,
    ),
  );
}
