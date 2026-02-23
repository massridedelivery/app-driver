import 'package:flutter/material.dart';
import 'package:massdrive/core/constants/app_spacing.dart';

class BadgeSizeState {
  final BadgeSize normal;
  final BadgeSize bold;

  const BadgeSizeState({required this.normal, required this.bold});

  BadgeSizeState copyWith({
    TextStyle? textStyle,
    EdgeInsetsGeometry? padding,
    double? cornerRadius,
    int? maxLines,
    TextOverflow? overflow,
    double? iconSize,
    double? iconPadding,
  }) {
    return BadgeSizeState(
      normal: normal.copyWith(
        textStyle: textStyle ?? normal.textStyle,
        padding: padding ?? normal.padding,
        cornerRadius: cornerRadius ?? normal.cornerRadius,
        maxLines: maxLines ?? normal.maxLines,
        overflow: overflow ?? normal.overflow,
        iconSize: iconSize ?? normal.iconSize,
        iconPadding: iconPadding ?? normal.iconPadding,
      ),
      bold: bold.copyWith(
        textStyle: textStyle ?? bold.textStyle,
        padding: padding ?? bold.padding,
        cornerRadius: cornerRadius ?? bold.cornerRadius,
        maxLines: maxLines ?? bold.maxLines,
        overflow: overflow ?? bold.overflow,
        iconSize: iconSize ?? bold.iconSize,
        iconPadding: iconPadding ?? bold.iconPadding,
      ),
    );
  }
}

enum BadgeFontType { normal, bold }

class BadgeSize {
  final TextStyle textStyle;
  final EdgeInsetsGeometry padding;
  final double cornerRadius;
  final int maxLines;
  final TextOverflow overflow;
  final double iconSize;
  final double iconPadding;

  const BadgeSize({
    required this.textStyle,
    required this.padding,
    required this.cornerRadius,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
    this.iconSize = AppSpacing.s5,
    this.iconPadding = AppSpacing.s2,
  });

  BadgeSize copyWith({
    TextStyle? textStyle,
    EdgeInsetsGeometry? padding,
    double? cornerRadius,
    int? maxLines,
    TextOverflow? overflow,
    double? iconSize,
    double? iconPadding,
  }) {
    return BadgeSize(
      textStyle: textStyle ?? this.textStyle,
      padding: padding ?? this.padding,
      cornerRadius: cornerRadius ?? this.cornerRadius,
      maxLines: maxLines ?? this.maxLines,
      overflow: overflow ?? this.overflow,
      iconSize: iconSize ?? this.iconSize,
      iconPadding: iconPadding ?? this.iconPadding,
    );
  }
}
