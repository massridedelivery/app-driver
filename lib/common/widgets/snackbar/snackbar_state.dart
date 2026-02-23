import 'package:flutter/material.dart';
import 'package:massdrive/common/widgets/snackbar/snackbar_style.dart';
import 'package:massdrive/common/widgets/snackbar/snackbar_styles.dart';

class SnackbarState {
  final String message;
  final SnackBarStyle style;
  final MainAxisAlignment textAlignment;
  final int delayedInMilliseconds;
  final bool isShow;

  SnackbarState({
    this.message = '',
    this.style = SnackBarStyles.informative,
    this.textAlignment = MainAxisAlignment.center,
    this.delayedInMilliseconds = 0,
    this.isShow = false,
  });

  SnackbarState copyWith({
    String? message,
    SnackBarStyle? style,
    MainAxisAlignment? textAlignment,
    int? delayedInMilliseconds,
    bool? isShow,
  }) => SnackbarState(
    message: message ?? this.message,
    style: style ?? this.style,
    textAlignment: textAlignment ?? this.textAlignment,
    delayedInMilliseconds: delayedInMilliseconds ?? this.delayedInMilliseconds,
    isShow: isShow ?? this.isShow,
  );
}
