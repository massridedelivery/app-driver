import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:massdrive/core/constants/app_colors.dart';

class ToastUtil {
  static void showSuccessToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.green,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  static void showErrorToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: AppColors.foundationOrange600,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }
}
