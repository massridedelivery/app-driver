import 'package:flutter/material.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_typography.dart';

/// Auth flow palette: white body + charcoal header, the MassCustomer layout in
/// the driver app's black-logo colours.
class AuthColors {
  AuthColors._();

  static const bg = Colors.white;
  // Neutrals match BrandColors.light (fill / line / text1–3).
  static const fieldFill = Color(0xFFF5F6F8);
  static const fieldBorder = Color(0xFFE7E9EE);
  static const textPrimary = Color(0xFF1B1D22);
  static const textSecondary = Color(0xFF6B7280);
  static const hint = Color(0xFF9CA3AF);
  static const disabledBg = Color(0xFFE7E9EE);
  static const disabledText = Color(0xFF9CA3AF);
  static const accent = AppColors.foundationRed700; // #DB1439
  static const charcoal = Color(0xFF3A3B40);
  static const charcoalDeep = Color(0xFF1D1E22);
}

/// Normalises what the driver typed after the `+66` prefix to the local
/// `0XXXXXXXXX` form the OTP endpoint expects. Both `812345678` and
/// `0812345678` give `0812345678`; empty stays empty.
String normalizeThaiPhone(String input) {
  final digits = input.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return '';
  return digits.startsWith('0') ? digits : '0$digits';
}

/// A Thai mobile number in local form: 10 digits starting with 0.
bool isValidThaiPhone(String normalized) =>
    RegExp(r'^0\d{9}$').hasMatch(normalized);

/// Black rounded tile with the white M and "MASS DRIVE" — the app icon.
class MassDriveLogoTile extends StatelessWidget {
  final double size;

  const MassDriveLogoTile({super.key, this.size = 64});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.25),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3B3C41), Color(0xFF1A1B1E)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/images/app_logo_mark.png', width: size * 0.62),
          SizedBox(height: size * 0.03),
          Text(
            'MASS DRIVE',
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.1,
              fontWeight: FontWeight.w700,
              letterSpacing: size * 0.01,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Charcoal header with faint service icons, the logo tile, a title and a
/// subtitle, ending in a wave into the white body.
class AuthHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onBack;

  const AuthHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.onBack,
  });

  static const _icons = 'assets/images/icons/vehicles';

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AuthColors.charcoal, AuthColors.charcoalDeep],
        ),
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          ..._faintIcons(top),
          Padding(
            padding: EdgeInsets.fromLTRB(20, top + 8, 20, 64),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 48,
                  child: onBack == null
                      ? null
                      : IconButton(
                          padding: EdgeInsets.zero,
                          alignment: Alignment.centerLeft,
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: onBack,
                        ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const MassDriveLogoTile(),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: AppTypography.heading3.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: AppTypography.caption4.copyWith(
                              color: Colors.white.withValues(alpha: 0.75),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: -1,
            child: SizedBox(
              height: 44,
              child: CustomPaint(painter: _WavePainter(AuthColors.bg)),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _faintIcons(double top) {
    Widget icon(String name, double w, {double? right, required double y}) =>
        Positioned(
          right: right,
          top: top + y,
          child: Opacity(
            opacity: 0.13,
            child: ColorFiltered(
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
              child: Image.asset('$_icons/$name', width: w),
            ),
          ),
        );
    return [
      icon('ic_car_scooter.png', 64, right: 72, y: 4),
      icon('ic_car_economy.png', 78, right: -6, y: 52),
      icon('ic3d_messenger.png', 48, right: 116, y: 96),
      icon('ic3d_food.png', 44, right: 24, y: 136),
    ];
  }
}

class _WavePainter extends CustomPainter {
  final Color color;

  const _WavePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(0, h * 0.45)
      ..cubicTo(w * 0.28, h, w * 0.61, 0, w, h * 0.5)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_WavePainter old) => old.color != color;
}

/// Full-width primary button: brand red when enabled, flat grey when not.
class AuthPrimaryButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final bool loading;
  final Future<void> Function() onTap;

  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.enabled,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: radius,
          onTap: enabled ? onTap : null,
          child: Ink(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: enabled ? AuthColors.accent : AuthColors.disabledBg,
              borderRadius: radius,
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: AuthColors.accent.withValues(alpha: 0.25),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: loading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      label,
                      style: AppTypography.label2.copyWith(
                        color: enabled ? Colors.white : AuthColors.disabledText,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
