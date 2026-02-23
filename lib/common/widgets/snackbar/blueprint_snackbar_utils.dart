import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:massdrive/common/widgets/snackbar/blueprint_snackbar.dart';
import 'package:massdrive/common/widgets/snackbar/snackbar_style.dart';
import 'package:massdrive/common/widgets/snackbar/snackbar_styles.dart';
import 'package:massdrive/core/constants/enum/result.dart';

void showSnackBar(
  BuildContext context,
  String message, {
  required SnackBarStyle style,
  MainAxisAlignment textAlignment = MainAxisAlignment.start,
}) {
  OverlayEntry? overlayEntry;

  overlayEntry = OverlayEntry(
    builder: (context) => BlueprintSnackBar(
      style: style,
      message: message,
      textAlignment: textAlignment,
      onDismissed: () {
        overlayEntry?.remove();
      },
    ),
  );

  Overlay.of(context).insert(overlayEntry);
}

// Override Function Extension
void showSnackBarInfoResult(
  BuildContext context, {
  required Result snackbarResult,
  MainAxisAlignment textAlignment = MainAxisAlignment.start,
}) {
  String snackBarMessage = '';
  SnackBarStyle style = SnackBarStyles.success;

  // 1. Use the Result.when extension to safely unwrap the message and determine the style.
  snackbarResult.when(
    // Case 1: Success
    success: (message) {
      snackBarMessage = message ?? '';
      style = SnackBarStyles.success;
    },
    // Case 2: Error
    error: (message) {
      snackBarMessage = message ?? '';
      style = SnackBarStyles.error;
    },
  );

  // The original showSnackBar function handles the OverlayEntry logic.
  showSnackBar(
    context,
    tr(snackBarMessage),
    style: style,
    textAlignment: textAlignment,
  );
}
