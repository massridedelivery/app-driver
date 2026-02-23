import 'package:massdrive/common/widgets/button/models/state_button_colors.dart';

class ButtonColors {
  final StateButtonColors foreground;
  final StateButtonColors background;
  final StateButtonColors? strokeColor;

  const ButtonColors({
    required this.foreground,
    required this.background,
    this.strokeColor,
  });
}
