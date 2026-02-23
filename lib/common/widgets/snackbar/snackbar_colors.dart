import 'package:massdrive/common/widgets/snackbar/snackbar_color.dart';
import 'package:massdrive/core/constants/app_colors.dart';

class SnackbarColors {
  static const success = SnackbarColor(
    foreground: AppColors.semanticGrayNeutralFgWhite,
    background: AppColors.semanticSuccessBgHigh,
  );

  static const error = SnackbarColor(
    foreground: AppColors.semanticGrayNeutralFgWhite,
    background: AppColors.semanticErrorBgMid,
  );

  static const warning = SnackbarColor(
    foreground: AppColors.semanticGrayNeutralFgMidOnGray,
    background: AppColors.semanticWarningBgHigh,
  );
  static const informative = SnackbarColor(
    foreground: AppColors.semanticGrayNeutralFgWhite,
    background: AppColors.semanticSecondaryBgHigh,
  );
}
