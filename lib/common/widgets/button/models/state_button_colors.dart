import 'package:flutter/material.dart';
import 'package:massdrive/core/constants/app_colors.dart';

class StateButtonColors {
  final Color enabled;
  final Color disabled;
  final Color? hovered;
  final Color? pressed;
  final Color? focused;
  final Color loading;

  const StateButtonColors({
    required this.enabled,
    required this.disabled,
    required this.loading,
    this.hovered,
    this.pressed,
    this.focused,
  });

  Color getInteractionColor({
    required bool isPressed,
    required bool isHovered,
    required bool isFocused,
    required bool isLoading,
    required bool isEnabled,
  }) {
    if (isPressed) return pressed ?? enabled;
    if (isHovered) return hovered ?? enabled;
    if (isFocused) return focused ?? enabled;
    if (isLoading) return loading;
    if (isEnabled) return enabled;
    return disabled;
  }
}

// Primary Button Colors
const foregroundButtonPrimary = StateButtonColors(
  disabled: AppColors.semanticDisabledFgOnGray,
  enabled: AppColors.semanticGrayNeutralFgWhite,
  loading: AppColors.semanticDisabledFgOnGray,
);

const backgroundButtonPrimary = StateButtonColors(
  disabled: AppColors.semanticDisabledBgLow,
  pressed: AppColors.semanticPrimaryBgHigh,
  hovered: AppColors.semanticPrimaryBgLow,
  focused: AppColors.semanticPrimaryBgMid,
  enabled: AppColors.semanticPrimaryBgMid,
  loading: AppColors.semanticDisabledBgLow,
);

// Secondary Button Colors
const foregroundButtonSecondary = StateButtonColors(
  disabled: AppColors.semanticDisabledFgOnGray,
  enabled: AppColors.semanticSecondaryFgHigh,
  loading: AppColors.semanticDisabledFgOnGray,
);

const backgroundButtonSecondary = StateButtonColors(
  disabled: AppColors.semanticDisabledBgLow,
  pressed: AppColors.semanticSecondaryBgLowOnGray,
  hovered: AppColors.semanticSecondaryBgLowOnWhite,
  focused: AppColors.semanticSecondaryBgLowOnGray,
  enabled: AppColors.semanticSecondaryBgLowOnGray,
  loading: AppColors.semanticDisabledBgLow,
);

const strokeButtonSecondary = StateButtonColors(
  disabled: AppColors.semanticDisabledBorderLow,
  pressed: AppColors.semanticSecondaryBorderHigh,
  hovered: AppColors.semanticSecondaryBorderLow,
  focused: AppColors.semanticSecondaryBorderLow,
  enabled: AppColors.semanticSecondaryBorderLow,
  loading: AppColors.semanticDisabledBorderLow,
);

// Default Button Colors
const foregroundButtonDefault = StateButtonColors(
  disabled: AppColors.semanticDisabledFgOnGray,
  pressed: AppColors.semanticPrimaryFgHigh,
  enabled: AppColors.semanticGrayNeutralFgHigh,
  loading: AppColors.semanticDisabledFgOnGray,
);

const backgroundButtonDefault = StateButtonColors(
  disabled: AppColors.semanticDisabledBgLow,
  pressed: AppColors.semanticSecondaryBgLowOnWhite,
  hovered: AppColors.semanticGrayNeutralBgLightgray,
  focused: AppColors.semanticGrayNeutralBgWhite,
  enabled: AppColors.semanticGrayNeutralBgWhite,
  loading: AppColors.semanticDisabledBgLow,
);

const strokeButtonDefault = StateButtonColors(
  disabled: AppColors.semanticDisabledBorderLow,
  pressed: AppColors.semanticPrimaryBorderHigh,
  hovered: AppColors.semanticGrayNeutralBorderLightgray,
  focused: AppColors.semanticGrayNeutralBorderLightgray,
  enabled: AppColors.semanticGrayNeutralBorderLightgray,
  loading: AppColors.semanticDisabledBorderLow,
);

// Ghost Primary Button Colors
const foregroundButtonGhostPrimary = StateButtonColors(
  disabled: AppColors.semanticDisabledFgOnWhite,
  enabled: AppColors.semanticPrimaryFgHigh,
  loading: AppColors.semanticDisabledFgOnWhite,
);

const backgroundButtonGhostPrimary = StateButtonColors(
  disabled: Colors.transparent,
  pressed: AppColors.semanticSecondaryBgLowOnGray,
  hovered: AppColors.semanticGrayNeutralBgLightgray,
  focused: Colors.transparent,
  enabled: Colors.transparent,
  loading: Colors.transparent,
);

// Ghost Neutral Black Button Colors
const foregroundButtonGhostNeutralBlack = StateButtonColors(
  disabled: AppColors.semanticDisabledFgOnWhite,
  enabled: AppColors.semanticGrayNeutralFgHigh,
  loading: AppColors.semanticDisabledFgOnWhite,
);

const backgroundButtonGhostNeutralBlack = StateButtonColors(
  disabled: Colors.transparent,
  pressed: AppColors.semanticGrayNeutralBgDarkgray,
  hovered: AppColors.semanticGrayNeutralBgLightgray,
  focused: Colors.transparent,
  enabled: Colors.transparent,
  loading: Colors.transparent,
);

// Ghost Neutral Black Stroke Button Colors
const strokeButtonGhostNeutralBlack = StateButtonColors(
  disabled: AppColors.semanticDisabledBorderLow,
  pressed: AppColors.semanticPrimaryBorderHigh,
  hovered: AppColors.semanticGrayNeutralBorderLightgray,
  focused: AppColors.semanticGrayNeutralBorderLightgray,
  enabled: AppColors.semanticGrayNeutralBorderLightgray,
  loading: AppColors.semanticDisabledBorderLow,
);

// Ghost Neutral White Button Colors
const foregroundButtonGhostNeutralWhite = StateButtonColors(
  disabled: AppColors.semanticDisabledFgOnWhite,
  enabled: AppColors.semanticGrayNeutralFgWhite,
  loading: AppColors.semanticDisabledFgOnWhite,
);

const backgroundButtonGhostNeutralWhite = StateButtonColors(
  disabled: Colors.transparent,
  pressed: AppColors.semanticGrayNeutralBgDarkgray,
  hovered: AppColors.semanticGrayNeutralBgLightgray,
  focused: Colors.transparent,
  enabled: Colors.transparent,
  loading: Colors.transparent,
);

// Ghost Danger Button Colors
const foregroundButtonGhostDanger = StateButtonColors(
  disabled: AppColors.semanticDisabledFgOnWhite,
  enabled: AppColors.semanticErrorFgHigh,
  loading: AppColors.semanticDisabledFgOnWhite,
);

const backgroundButtonGhostDanger = StateButtonColors(
  disabled: Colors.transparent,
  pressed: AppColors.semanticErrorBgLowOnGray,
  hovered: AppColors.semanticErrorBgLowOnWhite,
  focused: Colors.transparent,
  enabled: Colors.transparent,
  loading: Colors.transparent,
);

// Danger Button Colors
const foregroundButtonDanger = StateButtonColors(
  disabled: AppColors.semanticDisabledFgOnGray,
  enabled: AppColors.semanticGrayNeutralFgWhite,
  loading: AppColors.semanticDisabledFgOnGray,
);

const backgroundButtonDanger = StateButtonColors(
  disabled: AppColors.semanticDisabledBgLow,
  pressed: AppColors.semanticErrorBgHigh,
  hovered: Color(0xFFEE4767),
  focused: AppColors.semanticErrorBgMid,
  enabled: AppColors.semanticErrorBgMid,
  loading: AppColors.semanticDisabledBgLow,
);

// Overlay Button Colors
const foregroundButtonOverlay = StateButtonColors(
  disabled: AppColors.semanticDisabledFgOnGray,
  enabled: AppColors.semanticGrayNeutralFgWhite,
  loading: AppColors.semanticDisabledFgOnGray,
);

const backgroundButtonOverlay = StateButtonColors(
  disabled: AppColors.semanticDisabledBgLow,
  pressed: AppColors.semanticAlphaBlackBgHigh,
  hovered: AppColors.semanticAlphaBlackBgMid,
  focused: AppColors.semanticAlphaBlackBgLow,
  enabled: AppColors.semanticAlphaBlackBgLow,
  loading: AppColors.semanticDisabledBgLow,
);

// Success Button Colors
const foregroundButtonSuccess = StateButtonColors(
  disabled: AppColors.semanticDisabledFgOnGray,
  enabled: AppColors.semanticGrayNeutralFgWhite,
  loading: AppColors.semanticDisabledFgOnGray,
);

const backgroundButtonSuccess = StateButtonColors(
  disabled: AppColors.semanticDisabledBgLow,
  pressed: AppColors.semanticSupportMintFgOnLow,
  hovered: Color(0xFF0FB46C),
  focused: AppColors.semanticSuccessBgHigh,
  enabled: AppColors.semanticSuccessBgHigh,
  loading: AppColors.semanticDisabledBgLow,
);
