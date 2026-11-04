import 'package:flutter/material.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_typography.dart';

/// The home screen's go online / go offline control. It morphs between its
/// two looks while the home layout moves it (see [OnlineToggleButton.motion]):
///
/// - offline: a wide orange pill, "เริ่มรับงาน", centred above the status;
/// - online: a solid green rounded square (the status dot's green), as tall
///   as the status card, with a white power icon, beside it.
class OnlineToggleButton extends StatelessWidget {
  const OnlineToggleButton({
    super.key,
    required this.isOnline,
    required this.onTap,
    this.buttonKey,
  });

  final bool isOnline;
  final VoidCallback onTap;

  /// Put on the button itself, so the coach mark highlights just it.
  final Key? buttonKey;

  /// The pill's and the square's sizes, for the layout that places them.
  static const Size offlineSize = Size(176, 52);
  static const Size onlineSize = Size(64, 64);

  /// Shared by the morph here and the move in the home layout, so the button
  /// shrinks and slides as one.
  static const Duration motion = Duration(milliseconds: 380);
  static const Curve curve = Curves.easeOutCubic;

  @override
  Widget build(BuildContext context) {
    final size = isOnline ? onlineSize : offlineSize;
    final radius = BorderRadius.circular(isOnline ? 16 : 26);
    return Semantics(
      key: buttonKey,
      button: true,
      label: isOnline ? 'ปิดรับงาน' : 'เริ่มรับงาน',
      child: AnimatedContainer(
        duration: motion,
        curve: curve,
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          color: isOnline
              ? AppColors.semanticSupportMintBgHigh
              : AppColors.foundationOrange700,
          borderRadius: radius,
          boxShadow: const [
            BoxShadow(
              color: Colors.black38,
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: ClipRRect(
              borderRadius: radius,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: isOnline ? _online() : _offline(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _offline() => FittedBox(
    key: const ValueKey('offline'),
    fit: BoxFit.scaleDown,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.power_settings_new, color: Colors.white),
          const SizedBox(width: 10),
          Text(
            'เริ่มรับงาน',
            maxLines: 1,
            style: AppTypography.heading5.copyWith(color: Colors.white),
          ),
        ],
      ),
    ),
  );

  Widget _online() => const Center(
    key: ValueKey('online'),
    child: Icon(Icons.power_settings_new, size: 30, color: Colors.white),
  );
}
