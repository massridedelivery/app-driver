import 'package:flutter/material.dart';
import 'package:massdrive/core/theme/app_palette.dart';

/// One of the home screen's cards floating over the map (online control,
/// status, menu).
class HomeCard extends StatelessWidget {
  const HomeCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: context.palette.bg,
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [
        BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 2)),
      ],
    ),
    child: child,
  );
}
