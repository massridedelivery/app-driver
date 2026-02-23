import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:massdrive/core/constants/app_colors.dart';

class BaseWaveDotsIndicator extends StatelessWidget {
  final Color color;
  final double size;

  const BaseWaveDotsIndicator({
    super.key,
    this.color = AppColors.foundationOrange700,
    this.size = 50,
  });

  @override
  Widget build(BuildContext context) {
    return LoadingAnimationWidget.bouncingBall(color: color, size: size);
  }
}
