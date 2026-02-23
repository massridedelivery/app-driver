import 'package:massdrive/common/widgets/badge/models/badge_color.dart';
import 'package:massdrive/common/widgets/badge/models/badge_size.dart';

class BadgeStyle {
  final BadgeColorState color;
  final BadgeSizeState size;
  final BadgeType type;
  final BadgeFontType font;

  const BadgeStyle({
    required this.color,
    required this.size,
    this.type = BadgeType.high,
    this.font = BadgeFontType.normal,
  });
}

extension BadgeStyleExtension on BadgeStyle {
  BadgeColor _getColor() => switch (type) {
    BadgeType.high => color.high,
    BadgeType.mid => color.mid,
    BadgeType.low => color.low,
  };

  BadgeSize _getSize() => switch (font) {
    BadgeFontType.normal => size.normal,
    BadgeFontType.bold => size.bold,
  };

  ({BadgeColor color, BadgeSize size}) createStyle() {
    return (color: _getColor(), size: _getSize());
  }
}
