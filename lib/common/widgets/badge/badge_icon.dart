import 'package:flutter/material.dart';
import 'package:massdrive/common/images/asset_image.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/constants/enum/images.dart';

class BadgeIcon extends StatelessWidget {
  final String iconPath;
  final Color? color;
  final ImageFormat format;
  final int? badgeCount;
  final double? width;
  final double? height;

  const BadgeIcon({
    required this.iconPath,
    super.key,
    this.badgeCount,
    this.format = ImageFormat.svg,
    this.color = AppColors.semanticGrayNeutralFgHigh,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final displayIcon = AssetImageWidget(
      iconPath,
      color: color,
      format: format,
      width: width,
      height: height,
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        displayIcon,
        if ((badgeCount ?? 0) > 0)
          Positioned(
            top: -5,
            right: -8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.semanticErrorFgHigh,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: Colors.white, width: 1),
              ),
              constraints: const BoxConstraints(minHeight: 16, minWidth: 16),
              child: Text(
                badgeCount! > 99 ? '99+' : '$badgeCount',
                style: AppTypography.support1.copyWith(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
