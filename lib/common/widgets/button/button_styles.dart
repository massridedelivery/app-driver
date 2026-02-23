import 'package:massdrive/common/widgets/button/models/base_button_style.dart';
import 'package:massdrive/common/widgets/button/models/button_colors.dart';
import 'package:massdrive/common/widgets/button/models/button_size.dart';
import 'package:massdrive/core/constants/app_spacing.dart';
import 'package:massdrive/core/constants/app_typography.dart';

import 'models/state_button_colors.dart';

class ButtonStyle extends BaseButtonStyle {
  const ButtonStyle({required super.colors, super.size = _Sizes.lg});

  @override
  ButtonStyle copyWith({ButtonColors? colors, ButtonSize? size}) {
    return ButtonStyle(colors: colors ?? this.colors, size: size ?? this.size);
  }
}

abstract final class _ButtonColors {
  static const primary = ButtonColors(
    foreground: foregroundButtonPrimary,
    background: backgroundButtonPrimary,
  );

  static const secondary = ButtonColors(
    foreground: foregroundButtonSecondary,
    background: backgroundButtonSecondary,
    strokeColor: strokeButtonSecondary,
  );

  static const defaultStyle = ButtonColors(
    foreground: foregroundButtonDefault,
    background: backgroundButtonDefault,
    strokeColor: strokeButtonDefault,
  );

  static const ghostPrimary = ButtonColors(
    background: backgroundButtonGhostPrimary,
    foreground: foregroundButtonGhostPrimary,
  );

  static const ghostNeutralBlack = ButtonColors(
    background: backgroundButtonGhostNeutralBlack,
    foreground: foregroundButtonGhostNeutralBlack,
  );

  static const ghostNeutralBlackStroke = ButtonColors(
    background: backgroundButtonGhostNeutralBlack,
    foreground: foregroundButtonGhostNeutralBlack,
    strokeColor: strokeButtonGhostNeutralBlack,
  );

  static const ghostNeutralWhite = ButtonColors(
    background: backgroundButtonGhostNeutralWhite,
    foreground: foregroundButtonGhostNeutralWhite,
  );

  static const ghostDanger = ButtonColors(
    background: backgroundButtonGhostDanger,
    foreground: foregroundButtonGhostDanger,
  );

  static const danger = ButtonColors(
    background: backgroundButtonDanger,
    foreground: foregroundButtonDanger,
  );

  static const overlay = ButtonColors(
    background: backgroundButtonOverlay,
    foreground: foregroundButtonOverlay,
  );

  static const success = ButtonColors(
    background: backgroundButtonSuccess,
    foreground: foregroundButtonSuccess,
  );
}

abstract final class _Sizes {
  static const xl = ButtonSize(
    textStyle: AppTypography.label1,
    height: AppSpacing.s10,
    paddingHorizontal: AppSpacing.s6,
    iconPadding: AppSpacing.s3,
    iconSize: AppSpacing.s6,
    cornerRadius: AppSpacing.s4,
    minWidth: AppSpacing.s13 + AppSpacing.s11,
  );

  static const lg = ButtonSize(
    textStyle: AppTypography.label1,
    height: AppSpacing.s9,
    paddingHorizontal: AppSpacing.s5,
    iconPadding: AppSpacing.s3,
    iconSize: AppSpacing.s5,
    cornerRadius: AppSpacing.s4,
    minWidth: AppSpacing.s13 + AppSpacing.s8,
  );

  static const md = ButtonSize(
    textStyle: AppTypography.label2,
    height: AppSpacing.s8,
    paddingHorizontal: AppSpacing.s5,
    iconPadding: AppSpacing.s3,
    iconSize: AppSpacing.s5,
    cornerRadius: AppSpacing.rounded3,
    minWidth: 69,
  );

  static const sm = ButtonSize(
    textStyle: AppTypography.label3,
    height: AppSpacing.s7,
    paddingHorizontal: AppSpacing.s4,
    iconPadding: AppSpacing.rounded3,
    iconSize: AppSpacing.s4,
    cornerRadius: AppSpacing.rounded3,
    minWidth: AppSpacing.s11,
  );

  static const xs = ButtonSize(
    textStyle: AppTypography.label3,
    height: AppSpacing.s6 + AppSpacing.s2,
    paddingHorizontal: AppSpacing.s4,
    iconPadding: AppSpacing.rounded3,
    iconSize: AppSpacing.s4,
    cornerRadius: AppSpacing.rounded3,
    minWidth: AppSpacing.s11,
  );
}

abstract final class ButtonStyles {
  static const primary = ButtonStyle(colors: _ButtonColors.primary);
  static const secondary = ButtonStyle(colors: _ButtonColors.secondary);
  static const defaultStyle = ButtonStyle(colors: _ButtonColors.defaultStyle);
  static const ghostPrimary = ButtonStyle(colors: _ButtonColors.ghostPrimary);
  static const ghostNeutralBlack = ButtonStyle(
    colors: _ButtonColors.ghostNeutralBlack,
  );
  static const ghostNeutralBlackStroke = ButtonStyle(
    colors: _ButtonColors.ghostNeutralBlackStroke,
  );
  static const ghostNeutralWhite = ButtonStyle(
    colors: _ButtonColors.ghostNeutralWhite,
  );
  static const ghostDanger = ButtonStyle(colors: _ButtonColors.ghostDanger);
  static const danger = ButtonStyle(colors: _ButtonColors.danger);
  static const overlay = ButtonStyle(colors: _ButtonColors.overlay);
  static const success = ButtonStyle(colors: _ButtonColors.success);
}

extension ButtonStyleSizes on ButtonStyle {
  ButtonStyle get xl => copyWith(size: _Sizes.xl);

  ButtonStyle get lg => copyWith(size: _Sizes.lg);

  ButtonStyle get md => copyWith(size: _Sizes.md);

  ButtonStyle get sm => copyWith(size: _Sizes.sm);

  ButtonStyle get xs => copyWith(size: _Sizes.xs);
}
