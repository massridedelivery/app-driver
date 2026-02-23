import 'dart:ui';

class BadgeColorState {
  final BadgeColor high;
  final BadgeColor mid;
  final BadgeColor low;

  const BadgeColorState({
    required this.high,
    required this.mid,
    required this.low,
  });

  BadgeColorState copyWith({
    Color? backgroundColor,
    Color? textColor,
    Color? iconColor,
    Color? borderColor,
  }) {
    return BadgeColorState(
      high: high.copyWith(
        backgroundColor: backgroundColor ?? high.backgroundColor,
        textColor: textColor ?? high.textColor,
        iconColor: iconColor ?? high.iconColor,
        borderColor: borderColor ?? high.borderColor,
      ),
      mid: mid.copyWith(
        backgroundColor: backgroundColor ?? mid.backgroundColor,
        textColor: textColor ?? mid.textColor,
        iconColor: iconColor ?? mid.iconColor,
        borderColor: borderColor ?? mid.borderColor,
      ),
      low: low.copyWith(
        backgroundColor: backgroundColor ?? low.backgroundColor,
        textColor: textColor ?? low.textColor,
        iconColor: iconColor ?? low.iconColor,
        borderColor: borderColor ?? low.borderColor,
      ),
    );
  }
}

enum BadgeType { high, mid, low }

class BadgeColor {
  final Color backgroundColor;
  final Color textColor;
  final Color? iconColor;
  final Color? borderColor;

  const BadgeColor({
    required this.backgroundColor,
    required this.textColor,
    this.iconColor,
    this.borderColor,
  });

  BadgeColor copyWith({
    Color? backgroundColor,
    Color? textColor,
    Color? iconColor,
    Color? borderColor,
  }) {
    return BadgeColor(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      iconColor: iconColor ?? this.iconColor,
      borderColor: borderColor ?? this.borderColor,
    );
  }
}
