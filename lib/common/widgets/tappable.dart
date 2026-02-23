import 'package:flutter/widgets.dart';

class Tappable extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const Tappable({required this.onTap, required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: child,
    );
  }
}
