enum ImageFormat { png, jpg, gif, webp, svg }

extension ImageFormatExtension on ImageFormat {
  String get value => ['png', 'jpg', 'gif', 'webp', 'svg'][index];
}
