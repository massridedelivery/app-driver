import 'package:flutter/material.dart';

/// Red / white / charcoal brand palette ("design E") used by the driver
/// registration flow. Resolves light/dark from the ambient [Theme] brightness,
/// like [AppPalette]. Resolve via `context.brand`.
///
/// Usage rules:
/// - [red] only for the one primary button per screen, the current step /
///   progress ring, header icons, links and the focused field.
/// - [ok] (green) only for success / verified / money.
/// - [wait] (amber) for "in review".
/// - Rejected uses [bad] but always alongside a "!" icon and text.
class BrandColors {
  /// Primary brand red (buttons, ring, header icon, links, focus).
  final Color red;

  /// Pressed state of [red].
  final Color redPressed;

  /// Faint red wash (selected option, header icon tile).
  final Color tint;

  /// Page / scaffold background.
  final Color bg;

  /// Card / tile surface.
  final Color surface;

  /// Input / subtle container fill.
  final Color fill;

  /// Hairlines, borders, ring track, disabled button face.
  final Color line;

  final Color text1;
  final Color text2;
  final Color text3;

  final Color ok;
  final Color okBg;
  final Color wait;
  final Color waitBg;
  final Color bad;
  final Color badBg;

  final Brightness brightness;

  const BrandColors({
    required this.red,
    required this.redPressed,
    required this.tint,
    required this.bg,
    required this.surface,
    required this.fill,
    required this.line,
    required this.text1,
    required this.text2,
    required this.text3,
    required this.ok,
    required this.okBg,
    required this.wait,
    required this.waitBg,
    required this.bad,
    required this.badBg,
    required this.brightness,
  });

  bool get isDark => brightness == Brightness.dark;

  static const light = BrandColors(
    red: Color(0xFFDB1439),
    redPressed: Color(0xFFB71130),
    tint: Color(0xFFFEF1F3),
    bg: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    fill: Color(0xFFF5F6F8),
    line: Color(0xFFE7E9EE),
    text1: Color(0xFF1B1D22),
    text2: Color(0xFF6B7280),
    text3: Color(0xFF9CA3AF),
    ok: Color(0xFF12B76A),
    okBg: Color(0xFFECFDF3),
    wait: Color(0xFFB7791F),
    waitBg: Color(0xFFFFF7E6),
    bad: Color(0xFFDB1439),
    badBg: Color(0xFFFEF1F3),
    brightness: Brightness.light,
  );

  static const dark = BrandColors(
    red: Color(0xFFDB1439),
    redPressed: Color(0xFFB71130),
    tint: Color(0x24DB1439), // rgba(219,20,57,.14)
    bg: Color(0xFF121316),
    surface: Color(0xFF1E2026),
    fill: Color(0xFF23262D),
    line: Color(0xFF2C2F37),
    text1: Color(0xFFF3F4F6),
    text2: Color(0xFFA1A6B0),
    text3: Color(0xFF6B7180),
    ok: Color(0xFF32D583),
    okBg: Color(0x1F32D583), // rgba(50,213,131,.12)
    wait: Color(0xFFF5A524),
    waitBg: Color(0x1FF5A524), // rgba(245,165,36,.12)
    bad: Color(0xFFFF5C7A),
    badBg: Color(0x1FFF5C7A), // rgba(255,92,122,.12)
    brightness: Brightness.dark,
  );

  static BrandColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

extension BrandColorsContext on BuildContext {
  /// Red / white / charcoal brand tokens for the current brightness.
  BrandColors get brand => BrandColors.of(this);
}
