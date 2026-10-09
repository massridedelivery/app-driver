import 'package:flutter/material.dart';
import 'package:massdrive/core/constants/thai_banks.dart';

/// A square avatar identifying a Thai bank in the payout selector.
///
/// By default it renders an original brand-coloured badge with the bank code —
/// we deliberately do not ship the banks' trademarked logo artwork. If the team
/// adds official logo PNGs under `assets/images/banks/<code>.png`, declares that
/// folder in pubspec, and sets [useBundledLogos] to true, this will load them and
/// fall back to the badge for any missing file.
class BankLogoAvatar extends StatelessWidget {
  final ThaiBank bank;
  final double size;

  /// Flip to true once official logo assets are bundled + declared in pubspec.
  static const bool useBundledLogos = false;

  const BankLogoAvatar({super.key, required this.bank, this.size = 44});

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.26;
    final badge = _Badge(bank: bank, size: size, radius: radius);

    if (!useBundledLogos) return badge;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.asset(
        bank.logoAsset,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => badge,
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final ThaiBank bank;
  final double size;
  final double radius;

  const _Badge({required this.bank, required this.size, required this.radius});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      padding: EdgeInsets.all(size * 0.14),
      decoration: BoxDecoration(
        color: bank.brandColor,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          bank.code,
          style: TextStyle(
            color: bank.onBrandColor,
            fontWeight: FontWeight.w800,
            fontSize: size * 0.3,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}
