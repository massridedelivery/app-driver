import 'package:flutter/material.dart';
import 'package:massdrive/common/images/asset_image.dart';
import 'package:massdrive/common/widgets/badge/models/badge_styles.dart';
import '../../../core/constants/enum/images.dart';

class BlueprintBadge extends StatelessWidget {
  const BlueprintBadge({
    required this.style,
    required this.text,
    super.key,
    this.iconStart,
    this.iconEnd,
  });

  final BadgeStyle style;
  final String text;
  final String? iconStart;
  final String? iconEnd;

  @override
  Widget build(BuildContext context) {
    final displayStyle = style.createStyle();
    return Container(
      //height: style.height,
      decoration: BoxDecoration(
        color: displayStyle.color.backgroundColor,
        borderRadius: BorderRadius.circular(displayStyle.size.cornerRadius),
        border: Border.all(
          color:
              displayStyle.color.borderColor ??
              displayStyle.color.backgroundColor,
          width: 1.0,
          style: BorderStyle.solid,
        ),
      ),
      padding: displayStyle.size.padding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (iconStart != null) ...[
            _ButtonIcon(
              icon: iconStart!,
              size: displayStyle.size.iconSize,
              color: displayStyle.color.iconColor,
            ),
            SizedBox(width: displayStyle.size.iconPadding),
          ],
          Flexible(
            child: Text(
              text,
              maxLines: displayStyle.size.maxLines,
              overflow: displayStyle.size.overflow,
              style: displayStyle.size.textStyle.copyWith(
                color: displayStyle.color.textColor,
              ),
            ),
          ),
          if (iconEnd != null) ...[
            SizedBox(width: displayStyle.size.iconPadding),
            _ButtonIcon(
              icon: iconEnd!,
              size: displayStyle.size.iconSize,
              color: displayStyle.color.iconColor,
            ),
          ],
        ],
      ),
    );
  }
}

class _ButtonIcon extends StatelessWidget {
  const _ButtonIcon({required this.icon, required this.size, this.color});

  final String icon;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return AssetImageWidget(
      icon,
      color: color,
      width: size,
      height: size,
      format: ImageFormat.svg,
    );
  }
}
