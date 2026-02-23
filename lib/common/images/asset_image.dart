import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/enum/images.dart';
import 'package:massdrive/core/utils/image_util.dart';

class AssetImageWidget extends StatelessWidget {
  const AssetImageWidget(
    this.image, {
    super.key,
    this.width,
    this.height,
    this.cacheWidth,
    this.cacheHeight,
    this.fit,
    this.format = ImageFormat.png,
    this.color,
  });

  final String image;
  final double? width;
  final double? height;
  final int? cacheWidth;
  final int? cacheHeight;
  final BoxFit? fit;
  final ImageFormat format;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    switch (format) {
      case ImageFormat.svg:
        return SvgPicture.asset(
          ImageUtils.getImgPath(image, format: ImageFormat.svg),
          width: width,
          height: height,
          fit: fit ?? BoxFit.contain,
          colorFilter: color != null
              ? ColorFilter.mode(
                  color ?? AppColors.semanticAlphaBlackBgMid,
                  BlendMode.srcIn,
                )
              : null,
        );
      default:
        return Image.asset(
          ImageUtils.getImgPath(image, format: format),
          height: height,
          width: width,
          cacheWidth: cacheWidth,
          cacheHeight: cacheHeight,
          fit: fit,
          color: color,
          excludeFromSemantics: true,
          gaplessPlayback: true,
        );
    }
  }
}
