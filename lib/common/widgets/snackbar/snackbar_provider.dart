import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:massdrive/common/widgets/snackbar/snackbar_state.dart';
import 'package:massdrive/common/widgets/snackbar/snackbar_style.dart';

final snackbarProvider = NotifierProvider<SnackbarNotifier, SnackbarState>(
  SnackbarNotifier.new,
);

class SnackbarNotifier extends Notifier<SnackbarState> {
  @override
  SnackbarState build() => .new();

  /// Shows a snackbar by updating the current [SnackbarState].
  ///
  /// This method sets [isShow] to `true` and updates the snackbar content
  /// including [message], visual [style], and [textAlignment].
  ///
  /// Typically used to display feedback such as success, error, or warning
  /// messages from application logic without directly interacting with
  /// `ScaffoldMessenger`.
  ///
  /// Parameters:
  /// - [message]: The text displayed inside the snackbar.
  /// - [style]: Defines the snackbar appearance (colors, icons, etc.).
  /// - [textAlignment]: Controls alignment of the snackbar content.
  ///   Defaults to [MainAxisAlignment.center].
  /// - [delayedInMilliSecond]: Delay in milliseconds before showing the snackbar.
  ///   Defaults to 0.
  ///
  /// Example:
  /// ```dart
  /// ref.read(snackbarProvider.notifier).show(
  ///   message: tr('common.snackbar_info_saved_message'),
  ///   style: SnackBarStyles.success,
  ///   textAlignment: .start,
  ///   delayedInMilliSecond: 200,
  /// );
  /// ```
  void show({
    required String message,
    required SnackBarStyle style,
    MainAxisAlignment textAlignment = MainAxisAlignment.center,
    int delayedInMilliSecond = 0,
  }) {
    state = state.copyWith(
      message: message,
      style: style,
      textAlignment: textAlignment,
      delayedInMilliseconds: delayedInMilliSecond,
      isShow: true,
    );
  }

  void hide() {
    state = state.copyWith(isShow: false);
  }
}
