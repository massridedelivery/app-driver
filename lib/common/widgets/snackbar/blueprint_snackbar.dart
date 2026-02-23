import 'package:flutter/material.dart';
import 'package:massdrive/common/images/asset_image.dart';
import 'package:massdrive/common/widgets/snackbar/snackbar_style.dart';
import 'package:massdrive/core/constants/app_spacing.dart';
import 'package:massdrive/core/constants/app_typography.dart';

class BlueprintSnackBar extends StatefulWidget {
  const BlueprintSnackBar({
    required this.message,
    required this.onDismissed,
    required this.style,
    super.key,
    this.textAlignment = MainAxisAlignment.start,
  });

  final String message;
  final VoidCallback onDismissed;
  final SnackBarStyle style;
  final MainAxisAlignment textAlignment;

  @override
  State<BlueprintSnackBar> createState() => _BlueprintSnackBarState();
}

class _BlueprintSnackBarState extends State<BlueprintSnackBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _controller.reverse().then((_) {
          widget.onDismissed();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      child: SlideTransition(
        position: _offsetAnimation,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.only(
                  left: AppSpacing.s5,
                  right: AppSpacing.s5,
                  bottom: AppSpacing.s4,
                  top: AppSpacing.s4 + MediaQuery.of(context).padding.top,
                ),
                color: widget.style.color.background,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: widget.textAlignment,
                  spacing: AppSpacing.s3,
                  children: [
                    AssetImageWidget(
                      widget.style.icon,
                      width: 20,
                      height: 20,
                      format: .svg,
                      color: widget.style.color.foreground,
                    ),
                    Text(
                      widget.message,
                      style: AppTypography.caption4.copyWith(
                        color: widget.style.color.foreground,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
