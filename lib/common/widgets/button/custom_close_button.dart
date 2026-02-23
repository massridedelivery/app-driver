import 'package:flutter/material.dart';
import 'package:massdrive/common/images/asset_image.dart';
import 'package:massdrive/core/constants/app_assets.dart';
import 'package:massdrive/core/constants/app_spacing.dart';

import '../../../core/constants/enum/images.dart';

/// Close Button
class CustomCloseButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const CustomCloseButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topRight,
      child: IconButton(
        icon: const AssetImageWidget(
          AppAssets.crossIcon,
          width: AppSpacing.s6,
          format: ImageFormat.svg,
        ),
        style: IconButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
        ),
        onPressed: onPressed,
      ),
    );
  }
}
