import 'package:flutter/material.dart';

class AnnouncementState {
  final Color bgColor;
  final Color borderColor;
  final Color themeColor;
  final String icon;

  const AnnouncementState({
    required this.bgColor,
    required this.borderColor,
    required this.themeColor,
    required this.icon,
  });

  AnnouncementState copyWith({
    Color? bgColor,
    Color? borderColor,
    Color? themeColor,
    String? icon,
  }) {
    return AnnouncementState(
      bgColor: bgColor ?? this.bgColor,
      borderColor: borderColor ?? this.borderColor,
      themeColor: themeColor ?? this.themeColor,
      icon: icon ?? this.icon,
    );
  }
}
