import 'package:massdrive/common/widgets/snackbar/snackbar_colors.dart';
import 'package:massdrive/common/widgets/snackbar/snackbar_style.dart';
import 'package:massdrive/core/constants/app_assets.dart';

abstract final class SnackBarStyles {
  static const success = SnackBarStyle(
    icon: AppAssets.circleCheckFillIcon,
    color: SnackbarColors.success,
  );

  static const error = SnackBarStyle(
    icon: AppAssets.circleCrossFillIcon,
    color: SnackbarColors.error,
  );

  static const warning = SnackBarStyle(
    icon: AppAssets.hexagonExclamationLineIcon,
    color: SnackbarColors.warning,
  );

  static const informative = SnackBarStyle(
    icon: AppAssets.circleInformationLineIcon,
    color: SnackbarColors.informative,
  );
}
