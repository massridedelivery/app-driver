import 'package:flutter/material.dart';

class ButtonSize {
  final TextStyle textStyle;
  final double height;
  final double paddingHorizontal;
  final double iconPadding;
  final double iconSize;
  final double? cornerRadius;
  final double? width;
  final double? minWidth;

  const ButtonSize({
    required this.textStyle,
    required this.height,
    required this.paddingHorizontal,
    required this.iconPadding,
    required this.iconSize,
    this.cornerRadius,
    this.width,
    this.minWidth,
  });

  ButtonSize copyWith({
    TextStyle? textStyle,
    double? height,
    double? paddingHorizontal,
    double? iconPadding,
    double? iconSize,
    double? cornerRadius,
    double? width,
    double? minWidth,
  }) {
    return ButtonSize(
      textStyle: textStyle ?? this.textStyle,
      height: height ?? this.height,
      paddingHorizontal: paddingHorizontal ?? this.paddingHorizontal,
      iconPadding: iconPadding ?? this.iconPadding,
      iconSize: iconSize ?? this.iconSize,
      cornerRadius: cornerRadius ?? this.cornerRadius,
      width: width ?? this.width,
      minWidth: minWidth ?? this.minWidth,
    );
  }
}
