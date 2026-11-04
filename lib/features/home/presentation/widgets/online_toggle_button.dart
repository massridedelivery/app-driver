import 'package:flutter/material.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_typography.dart';

/// The home screen's go online / go offline control; the home layout places
/// it, so the two states are told apart by place as well as by look:
///
/// - offline: a wide orange pill, "เริ่มรับงาน", centred above the status;
/// - online: a small white rounded square with a green power icon and a
///   green dot, beside the status.
///
/// No animation: it switches in place.
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

  @override
  Widget build(BuildContext context) => KeyedSubtree(
    key: buttonKey,
    child: isOnline ? _online() : _offline(),
  );

  Widget _offline() => Semantics(
    button: true,
    label: 'เริ่มรับงาน',
    child: Material(
      color: AppColors.foundationOrange700,
      elevation: 6,
      shadowColor: Colors.black54,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.power_settings_new, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                'เริ่มรับงาน',
                style: AppTypography.heading5.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _online() => Semantics(
    button: true,
    label: 'ปิดรับงาน',
    child: Material(
      color: Colors.white,
      elevation: 6,
      shadowColor: Colors.black54,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: SizedBox(
          width: 52,
          height: 52,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(
                Icons.power_settings_new,
                size: 28,
                color: AppColors.semanticSupportMintBgHigh,
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: AppColors.semanticSupportMintBgHigh,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
