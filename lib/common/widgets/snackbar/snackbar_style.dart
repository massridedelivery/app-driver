import 'package:massdrive/common/widgets/snackbar/snackbar_color.dart';

class SnackBarStyle {
  final String icon;
  final SnackbarColor color;

  const SnackBarStyle({required this.icon, required this.color});

  SnackBarStyle copyWith({String? icon, SnackbarColor? color}) {
    return SnackBarStyle(icon: icon ?? this.icon, color: color ?? this.color);
  }
}
