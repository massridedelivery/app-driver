import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:massdrive/core/utils/image_util.dart';

class AppNetworkImage extends StatelessWidget {
  final String? imageUrl;
  final String holderImg;
  final double? width;
  final double? height;
  final BoxFit fit;

  const AppNetworkImage({
    required this.imageUrl,
    super.key,
    this.holderImg = 'img_placeholder_logo_square_rounded',
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final bool isUrlValid =
        imageUrl != null &&
        imageUrl!.isNotEmpty &&
        ImageUtils.isValidImageUrl(imageUrl!);

    if (!isUrlValid) {
      return Image.asset(
        ImageUtils.getImgPath(holderImg),
        width: width,
        height: height,
        fit: fit,
      );
    }

    if (ImageUtils.isSvgImageUrl(imageUrl!)) {
      return SvgPicture.network(
        imageUrl!,
        width: width,
        height: height,
        fit: fit,
        placeholderBuilder: (context) =>
            Image.asset(ImageUtils.getImgPath(holderImg)),
      );
    }

    // Decode into memory at (roughly) display resolution instead of the image's
    // full size — a large avatar/banner decoded full-res can cost several MB
    // each. Multiply by devicePixelRatio so it still looks sharp.
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final memCacheWidth = width != null ? (width! * dpr).round() : null;
    final memCacheHeight = height != null ? (height! * dpr).round() : null;

    return CachedNetworkImage(
      imageUrl: imageUrl!,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      placeholder: (context, url) => Image.asset(
        ImageUtils.getImgPath(holderImg),
        width: width,
        height: height,
        fit: fit,
      ),
      errorWidget: (context, url, error) => Image.asset(
        ImageUtils.getImgPath(holderImg),
        width: width,
        height: height,
        fit: fit,
      ),
    );
  }
}
