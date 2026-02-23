import 'package:flutter/material.dart';

class AnnouncementSize {
  final TextStyle titleTextStyle;
  final TextStyle descriptionTextStyle;

  const AnnouncementSize({
    required this.titleTextStyle,
    required this.descriptionTextStyle,
  });

  AnnouncementSize copyWith({
    TextStyle? titleTextStyle,
    TextStyle? descriptionTextStyle,
  }) {
    return AnnouncementSize(
      titleTextStyle: titleTextStyle ?? this.titleTextStyle,
      descriptionTextStyle: descriptionTextStyle ?? this.descriptionTextStyle,
    );
  }
}
