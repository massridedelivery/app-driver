import 'package:massdrive/common/widgets/button/models/button_colors.dart';
import 'package:massdrive/common/widgets/button/models/button_size.dart';

class BaseButtonStyle {
  final ButtonSize size;
  final ButtonColors colors;

  const BaseButtonStyle({required this.size, required this.colors});

  BaseButtonStyle copyWith({ButtonSize? size, ButtonColors? colors}) {
    return BaseButtonStyle(
      size: size ?? this.size,
      colors: colors ?? this.colors,
    );
  }
}
