import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:massdrive/core/constants/enum/images.dart';

class ImageUtils {
  static ImageProvider getAssetImage(
    String name, {
    ImageFormat format = ImageFormat.png,
  }) {
    return AssetImage(getImgPath(name, format: format));
  }

  static String getImgPath(
    String name, {
    ImageFormat format = ImageFormat.png,
  }) {
    return 'assets/images/$name.${format.value}';
  }

  static ImageProvider getImageProvider(
    String? imageUrl, {
    String holderImg = 'img_placeholder_logo_square_rounded',
  }) {
    final bool isUrlValid =
        imageUrl != null && imageUrl.isNotEmpty && isValidImageUrl(imageUrl);
    if (!isUrlValid) {
      // Return the placeholder if the URL is invalid, empty, or null.
      return AssetImage(getImgPath(holderImg));
    }
    return CachedNetworkImageProvider(imageUrl);
  }

  static bool isValidImageUrl(String url) {
    final RegExp imageUrlPattern = RegExp(
      r'^(https?:\/\/.*\.(?:png|jpg|jpeg|gif|svg|webp))$',
      caseSensitive: false,
    );
    return imageUrlPattern.hasMatch(url);
  }

  static bool isSvgImageUrl(String url) {
    final RegExp imageUrlPattern = RegExp(
      r'^(https?:\/\/.*\.(?:svg))$',
      caseSensitive: false,
    );
    return imageUrlPattern.hasMatch(url);
  }
}
