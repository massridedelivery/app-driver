import 'package:flutter/material.dart';
import 'package:massdrive/common/images/asset_image.dart';
import 'package:massdrive/common/widgets/button/models/base_button_style.dart';
import 'package:massdrive/common/widgets/button/models/state_button_colors.dart';

import '../../../core/constants/enum/images.dart';

class BlueprintButton extends StatelessWidget {
  const BlueprintButton({
    required this.style,
    required this.onPressed,
    super.key,
    this.text,
    this.iconStart,
    this.iconEnd,
    this.isEnabled = true,
    this.isLoading = false,
    this.maxLines = 1,
  });

  final BaseButtonStyle style;
  final String? text;
  final String? iconStart;
  final String? iconEnd;
  final bool isEnabled;
  final bool isLoading;
  final int maxLines;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = _ButtonColors(
      style: style,
      isEnabled: isEnabled,
      isLoading: isLoading,
    );

    final isButtonEnabled = isEnabled && !isLoading;

    Widget button = ElevatedButton(
      onPressed: isButtonEnabled ? onPressed : null,
      style: _buttonStyle(colors),
      child: _ButtonContent(
        text: text,
        iconStart: iconStart,
        iconEnd: iconEnd,
        isLoading: isLoading,
        style: style,
        foregroundColor: colors.foreground,
      ),
    );

    if (style.size.minWidth != null) {
      button = ConstrainedBox(
        constraints: BoxConstraints(minWidth: style.size.minWidth!),
        child: button,
      );
    }

    return SizedBox(
      width: style.size.width,
      height: style.size.height,
      child: button,
    );
  }

  ButtonStyle _buttonStyle(_ButtonColors colors) {
    return ElevatedButton.styleFrom(
      foregroundColor: colors.foreground,
      backgroundColor: colors.background,
      disabledForegroundColor: style.colors.foreground.disabled,
      disabledBackgroundColor: style.colors.background.disabled,
      shape: _borderShape,
      side: colors.stroke != null ? BorderSide(color: colors.stroke!) : null,
      padding: EdgeInsets.symmetric(horizontal: style.size.paddingHorizontal),
      elevation: 0,
      shadowColor: Colors.transparent,
    );
  }

  OutlinedBorder get _borderShape {
    final radius = style.size.cornerRadius;
    return radius != null
        ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius))
        : const RoundedRectangleBorder();
  }
}

class _ButtonColors {
  const _ButtonColors({
    required this.style,
    required this.isEnabled,
    required this.isLoading,
  });

  final BaseButtonStyle style;
  final bool isEnabled;
  final bool isLoading;

  Color get foreground =>
      style.colors.foreground._getColor(isEnabled, isLoading);

  Color get background =>
      style.colors.background._getColor(isEnabled, isLoading);

  Color? get stroke =>
      style.colors.strokeColor?._getColor(isEnabled, isLoading);
}

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({
    required this.text,
    required this.iconStart,
    required this.iconEnd,
    required this.isLoading,
    required this.style,
    required this.foregroundColor,
  });

  final String? text;
  final String? iconStart;
  final String? iconEnd;
  final bool isLoading;
  final BaseButtonStyle style;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLoading) ...[
          _LoadingIndicator(size: style.size.iconSize, color: foregroundColor),
          SizedBox(width: style.size.iconPadding),
        ],
        if (iconStart != null) ...[
          _ButtonIcon(
            icon: iconStart!,
            size: style.size.iconSize,
            color: foregroundColor,
          ),
          SizedBox(width: style.size.iconPadding),
        ],
        if (text != null)
          _ButtonText(
            text: text!,
            style: style.size.textStyle,
            color: foregroundColor,
          ),
        if (iconEnd != null) ...[
          SizedBox(width: style.size.iconPadding),
          _ButtonIcon(
            icon: iconEnd!,
            size: style.size.iconSize,
            color: foregroundColor,
          ),
        ],
      ],
    );
  }
}

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(color: color, strokeWidth: 2.0),
    );
  }
}

class _ButtonIcon extends StatelessWidget {
  const _ButtonIcon({
    required this.icon,
    required this.size,
    required this.color,
  });

  final String icon;
  final double size;
  final Color color;

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

class _ButtonText extends StatelessWidget {
  const _ButtonText({
    required this.text,
    required this.style,
    required this.color,
  });

  final String text;
  final TextStyle style;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Text(
        text,
        style: style.copyWith(color: color),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

extension on StateButtonColors {
  Color _getColor(bool isEnabled, bool isLoading) {
    return getInteractionColor(
      isPressed: false,
      isHovered: false,
      isFocused: false,
      isLoading: isLoading,
      isEnabled: isEnabled,
    );
  }
}
