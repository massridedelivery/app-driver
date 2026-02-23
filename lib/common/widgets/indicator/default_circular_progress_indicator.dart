import 'package:flutter/material.dart';
import 'package:massdrive/core/constants/app_colors.dart';

class DefaultCircularProgressIndicator extends CircularProgressIndicator {
  const DefaultCircularProgressIndicator({super.key});

  @override
  Color? get color => AppColors.semanticPrimaryBgMid;
}
