import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/theme/brand_colors.dart';

import '../../domain/models/registration_status.dart';

// Shared building blocks for the driver registration flow ("design E – white
// header", red / white / charcoal). Every screen in the flow composes these so
// the header, fields, buttons and status rows look identical. Colours come
// from `context.brand` and flip with the theme brightness.

// ---------------------------------------------------------------------------
// Step numbering
// ---------------------------------------------------------------------------

/// The items of the registration checklist, in display order.
enum RegistrationItem {
  profile,
  profilePhoto,
  idCard,
  drivingLicense,
  publicDrivingLicense,
  vehicle,
  vehiclePhoto,
  insurance,
  bank,
  consent;

  static RegistrationItem fromDocument(DocumentType type) => switch (type) {
    DocumentType.profilePhoto => RegistrationItem.profilePhoto,
    DocumentType.idCard => RegistrationItem.idCard,
    DocumentType.drivingLicense => RegistrationItem.drivingLicense,
    DocumentType.publicDrivingLicense => RegistrationItem.publicDrivingLicense,
    DocumentType.vehicleRegistration => RegistrationItem.vehicle,
    DocumentType.vehiclePhoto => RegistrationItem.vehiclePhoto,
    DocumentType.insurance => RegistrationItem.insurance,
    DocumentType.bankPassbook => RegistrationItem.bank,
  };
}

/// Checklist items shown for [tier] (consent excluded), in order. Food only
/// needs the core documents; ride / both add the vehicle documents.
List<RegistrationItem> registrationItemsFor(KycTier tier) => [
  RegistrationItem.profile,
  RegistrationItem.profilePhoto,
  RegistrationItem.idCard,
  RegistrationItem.drivingLicense,
  if (tier != KycTier.food) ...[
    RegistrationItem.publicDrivingLicense,
    RegistrationItem.vehicle,
    RegistrationItem.vehiclePhoto,
    RegistrationItem.insurance,
  ],
  RegistrationItem.bank,
];

/// Number of checklist items for [tier] (food 5, ride / both 9).
int registrationTotalSteps(KycTier tier) => registrationItemsFor(tier).length;

/// 1-based position of [item] in the checklist for [tier], or null when the
/// tier is unknown or the item isn't part of it. Consent counts as the last
/// step (total / total).
int? registrationStepNumber(KycTier? tier, RegistrationItem item) {
  if (tier == null) return null;
  final items = registrationItemsFor(tier);
  if (item == RegistrationItem.consent) return items.length;
  final i = items.indexOf(item);
  return i < 0 ? null : i + 1;
}

// ---------------------------------------------------------------------------
// Scaffold + header
// ---------------------------------------------------------------------------

/// Page frame for the registration flow: white header (back arrow, MASS DRIVE
/// mark, icon tile, title, subtitle, optional progress ring), a content sheet
/// with a hairline rounded top edge, and an optional pinned bottom CTA.
class RegistrationScaffold extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  /// Progress ring values; the ring is hidden unless both are set.
  final int? step;
  final int? total;

  /// Back action; defaults to `Navigator.maybePop`.
  final VoidCallback? onBack;
  final bool showBack;

  final Widget child;

  /// Wrap [child] in a padded scroll view (default). When false, [child] is
  /// laid out in the sheet with the same padding and must size itself.
  final bool scrollable;

  /// Pinned bottom area, normally a [RegistrationPrimaryButton].
  final Widget? bottom;

  const RegistrationScaffold({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.subtitle,
    this.step,
    this.total,
    this.onBack,
    this.showBack = true,
    this.scrollable = true,
    this.bottom,
  });

  static const EdgeInsets contentPadding = EdgeInsets.fromLTRB(16, 18, 16, 18);

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final content = scrollable
        ? SingleChildScrollView(padding: contentPadding, child: child)
        : Padding(padding: contentPadding, child: child);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: brand.isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: brand.bg,
        body: Column(
          children: [
            SafeArea(
              bottom: false,
              child: RegistrationHeader(
                icon: icon,
                title: title,
                subtitle: subtitle,
                step: step,
                total: total,
                onBack: onBack,
                showBack: showBack,
              ),
            ),
            Expanded(
              child: CustomPaint(
                foregroundPainter: _TopHairlinePainter(
                  color: brand.line,
                  radius: 22,
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(22),
                  ),
                  child: bottom == null
                      ? SafeArea(top: false, child: content)
                      : content,
                ),
              ),
            ),
            if (bottom != null)
              ColoredBox(
                color: brand.bg,
                child: SafeArea(
                  top: false,
                  minimum: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    child: bottom,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// White header: back arrow + MASS DRIVE mark, then icon tile, title /
/// subtitle and an optional [RegistrationProgressRing].
class RegistrationHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final int? step;
  final int? total;
  final VoidCallback? onBack;
  final bool showBack;

  const RegistrationHeader({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.step,
    this.total,
    this.onBack,
    this.showBack = true,
  });

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final showRing = step != null && total != null && total! > 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 40,
            child: Row(
              children: [
                if (showBack)
                  IconButton(
                    onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).backButtonTooltip,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 40,
                      height: 40,
                    ),
                    style: IconButton.styleFrom(
                      alignment: Alignment.centerLeft,
                    ),
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      size: 24,
                      color: brand.text1,
                    ),
                  ),
                const Spacer(),
                Text(
                  'MASS DRIVE',
                  style: AppTypography.support1.copyWith(
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w700,
                    color: brand.text1.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: brand.tint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 21, color: brand.red),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: AppTypography.heading4.copyWith(
                        color: brand.text1,
                        height: 1.25,
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle!,
                        style: AppTypography.body3.copyWith(
                          color: brand.text2,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (showRing) ...[
                const SizedBox(width: 10),
                RegistrationProgressRing(step: step!, total: total!),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// 50px progress ring: [BrandColors.line] track, red progress, surface centre
/// with "step/total".
class RegistrationProgressRing extends StatelessWidget {
  final int step;
  final int total;

  const RegistrationProgressRing({
    super.key,
    required this.step,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final progress = total <= 0 ? 0.0 : (step / total).clamp(0.0, 1.0);
    return Semantics(
      label: '$step/$total',
      excludeSemantics: true,
      child: SizedBox(
        width: 50,
        height: 50,
        child: CustomPaint(
          painter: _RingPainter(
            progress: progress,
            track: brand.line,
            color: brand.red,
          ),
          child: Center(
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: brand.surface,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '$step',
                      style: AppTypography.label3.copyWith(
                        fontSize: 13,
                        color: brand.text1,
                      ),
                    ),
                    TextSpan(
                      text: '/$total',
                      style: AppTypography.support1.copyWith(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: brand.text2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color track;
  final Color color;

  _RingPainter({
    required this.progress,
    required this.track,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 5.0;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawArc(rect, 0, math.pi * 2, false, paint..color = track);
    if (progress > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        math.pi * 2 * progress,
        false,
        paint..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.track != track || old.color != color;
}

/// 1px hairline along the top edge of the sheet, following its rounded
/// corners and fading out down the sides (CSS `border-top` + radius).
class _TopHairlinePainter extends CustomPainter {
  final Color color;
  final double radius;

  _TopHairlinePainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final r = math.min(radius, size.width / 2);
    final path = Path()
      ..moveTo(0, r)
      ..arcToPoint(Offset(r, 0.5), radius: Radius.circular(r))
      ..lineTo(size.width - r, 0.5)
      ..arcToPoint(Offset(size.width, r), radius: Radius.circular(r));
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_TopHairlinePainter old) =>
      old.color != color || old.radius != radius;
}

// ---------------------------------------------------------------------------
// Fields
// ---------------------------------------------------------------------------

/// Shared input decoration: filled [BrandColors.fill], radius 12, no border;
/// focused → 1.5px red border on a surface fill; errors in [BrandColors.bad].
InputDecoration registrationInputDecoration(
  BuildContext context, {
  String? hint,
  Widget? prefixIcon,
  Widget? suffixIcon,
  String? counterText = '',
}) {
  final brand = context.brand;
  OutlineInputBorder border(Color? c) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: c == null ? BorderSide.none : BorderSide(color: c, width: 1.5),
  );
  return InputDecoration(
    hintText: hint,
    hintStyle: AppTypography.caption4.copyWith(color: brand.text3),
    filled: true,
    fillColor: WidgetStateColor.resolveWith(
      (states) =>
          states.contains(WidgetState.focused) ? brand.surface : brand.fill,
    ),
    hoverColor: Colors.transparent,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    counterText: counterText,
    border: border(null),
    enabledBorder: border(null),
    disabledBorder: border(null),
    focusedBorder: border(brand.red),
    errorBorder: border(brand.bad),
    focusedErrorBorder: border(brand.bad),
    errorStyle: AppTypography.caption5.copyWith(color: brand.bad),
    errorMaxLines: 2,
  );
}

/// Text style for values typed into registration fields.
TextStyle registrationInputStyle(BuildContext context) =>
    AppTypography.label2.copyWith(color: context.brand.text1);

/// Label-above wrapper for a field. The label turns red while any descendant
/// (the input) has focus.
class RegistrationField extends StatefulWidget {
  final String label;
  final Widget child;

  /// Optional helper line under the field (text3), e.g. a format hint.
  final String? helper;

  const RegistrationField({
    super.key,
    required this.label,
    required this.child,
    this.helper,
  });

  @override
  State<RegistrationField> createState() => _RegistrationFieldState();
}

class _RegistrationFieldState extends State<RegistrationField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              widget.label,
              style: AppTypography.caption5.copyWith(
                color: _focused ? brand.red : brand.text2,
              ),
            ),
          ),
          Focus(
            canRequestFocus: false,
            skipTraversal: true,
            onFocusChange: (f) => setState(() => _focused = f),
            child: widget.child,
          ),
          if (widget.helper != null)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 2),
              child: Text(
                widget.helper!,
                style: AppTypography.caption5.copyWith(color: brand.text3),
              ),
            ),
        ],
      ),
    );
  }
}

/// Field-shaped tappable box for non-text inputs (date picker, bank picker,
/// read-only values). Matches [registrationInputDecoration].
class RegistrationFieldBox extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool error;

  const RegistrationFieldBox({
    super.key,
    required this.child,
    this.onTap,
    this.error = false,
  });

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final radius = BorderRadius.circular(12);
    return Material(
      color: brand.fill,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: error
            ? BorderSide(color: brand.bad, width: 1.5)
            : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Small error line in [BrandColors.bad], aligned with field errors.
class RegistrationErrorText extends StatelessWidget {
  final String text;
  const RegistrationErrorText(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6, left: 2),
    child: Text(
      text,
      style: AppTypography.caption5.copyWith(color: context.brand.bad),
    ),
  );
}

/// Section divider label (top hairline + small grey heading).
class RegistrationSectionLabel extends StatelessWidget {
  final String text;
  const RegistrationSectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return Container(
      margin: const EdgeInsets.only(top: 6, bottom: 12),
      padding: const EdgeInsets.only(top: 14),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: brand.line)),
      ),
      child: Text(
        text,
        style: AppTypography.caption5.copyWith(
          color: brand.text2,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Buttons
// ---------------------------------------------------------------------------

/// The one red primary CTA per screen. Height 50, radius 14. Pressed →
/// [BrandColors.redPressed]; disabled (null [onPressed] and not [loading]) →
/// [BrandColors.line] face with [BrandColors.text3] label. While [loading]
/// it keeps the red face, shows a spinner and ignores taps.
class RegistrationPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  const RegistrationPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final enabled = onPressed != null || loading;
    return IgnorePointer(
      ignoring: loading,
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: enabled ? (onPressed ?? () {}) : null,
          style: ButtonStyle(
            elevation: const WidgetStatePropertyAll(0),
            shadowColor: const WidgetStatePropertyAll(Colors.transparent),
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 16),
            ),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.disabled)) return brand.line;
              if (states.contains(WidgetState.pressed)) return brand.redPressed;
              return brand.red;
            }),
            foregroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.disabled)
                  ? brand.text3
                  : Colors.white,
            ),
          ),
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.2,
                  ),
                )
              : Text(
                  label,
                  textAlign: TextAlign.center,
                  style: AppTypography.label2.copyWith(
                    color: enabled ? Colors.white : brand.text3,
                  ),
                ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Option card (tier selection)
// ---------------------------------------------------------------------------

class RegistrationOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? badge;
  final bool selected;
  final VoidCallback onTap;

  const RegistrationOptionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final radius = BorderRadius.circular(14);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: selected ? brand.tint : brand.surface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: selected ? brand.red : brand.line,
            width: 1.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: selected ? brand.surface : brand.fill,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 21,
                    color: selected ? brand.red : brand.text2,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: AppTypography.label2.copyWith(
                                color: brand.text1,
                              ),
                            ),
                          ),
                          if (badge != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: selected ? brand.surface : brand.fill,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                badge!,
                                style: AppTypography.support2.copyWith(
                                  color: brand.text2,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppTypography.body3.copyWith(
                          color: brand.text2,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _Radio(selected: selected),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  final bool selected;
  const _Radio({required this.selected});

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? brand.red : brand.text3,
          width: selected ? 5.5 : 2,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Checklist status row
// ---------------------------------------------------------------------------

enum RegistrationRowStatus { todo, done, review, rejected }

class RegistrationStatusRow extends StatelessWidget {
  final int number;
  final String title;
  final RegistrationRowStatus status;

  /// Status lines under the title, coloured by [status].
  final List<String> statusLines;

  /// Index into [statusLines] to underline (e.g. "แตะเพื่ออัปโหลดใหม่").
  final int? underlineLine;
  final VoidCallback onTap;

  const RegistrationStatusRow({
    super.key,
    required this.number,
    required this.title,
    required this.status,
    required this.onTap,
    this.statusLines = const [],
    this.underlineLine,
  });

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final (Color circleBg, Color fg, IconData? icon) = switch (status) {
      RegistrationRowStatus.done => (brand.okBg, brand.ok, Icons.check_rounded),
      RegistrationRowStatus.review => (
        brand.waitBg,
        brand.wait,
        Icons.hourglass_top_rounded,
      ),
      RegistrationRowStatus.rejected => (
        brand.badBg,
        brand.bad,
        Icons.priority_high_rounded,
      ),
      RegistrationRowStatus.todo => (brand.fill, brand.text2, null),
    };
    final statusColor = status == RegistrationRowStatus.todo ? brand.text3 : fg;
    final radius = BorderRadius.circular(12);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: brand.surface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: status == RegistrationRowStatus.rejected
                ? brand.bad
                : brand.line,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: circleBg,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: icon != null
                      ? Icon(icon, size: 16, color: fg)
                      : Text(
                          '$number',
                          style: AppTypography.label3.copyWith(
                            fontSize: 11,
                            color: fg,
                          ),
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.label2.copyWith(
                          color: brand.text1,
                        ),
                      ),
                      for (var i = 0; i < statusLines.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            statusLines[i],
                            style: AppTypography.caption5.copyWith(
                              color: statusColor,
                              decoration: i == underlineLine
                                  ? TextDecoration.underline
                                  : null,
                              decorationColor: statusColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.chevron_right_rounded, color: brand.text3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Upload box
// ---------------------------------------------------------------------------

/// Dashed upload card: preview (or placeholder art), a bold label and either
/// "ถ่ายรูป" / "คลังภาพ" chips (when both [onCamera] and [onGallery] are set)
/// or just the tappable box ([onTap]).
class RegistrationUploadBox extends StatelessWidget {
  /// Image / loader to show; null → placeholder art.
  final Widget? preview;
  final String label;
  final VoidCallback? onTap;
  final VoidCallback? onCamera;
  final VoidCallback? onGallery;
  final double previewHeight;

  const RegistrationUploadBox({
    super.key,
    required this.label,
    this.preview,
    this.onTap,
    this.onCamera,
    this.onGallery,
    this.previewHeight = 160,
  });

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final hasChips = onCamera != null && onGallery != null;
    final radius = BorderRadius.circular(14);

    final previewArea = SizedBox(
      height: previewHeight,
      width: double.infinity,
      child: preview != null
          ? ClipRRect(borderRadius: BorderRadius.circular(10), child: preview)
          : Center(
              child: Container(
                width: 180,
                height: previewHeight * 0.7,
                decoration: BoxDecoration(
                  color: brand.fill,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: brand.line, width: 1.5),
                ),
                child: Icon(
                  Icons.add_photo_alternate_outlined,
                  size: 36,
                  color: brand.text3,
                ),
              ),
            ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: CustomPaint(
        foregroundPainter: _DashedRRectPainter(
          color: brand.line,
          radius: 14,
          strokeWidth: 1.5,
        ),
        child: Material(
          color: brand.surface,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  previewArea,
                  const SizedBox(height: 10),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: AppTypography.label3.copyWith(
                      fontSize: 13,
                      color: brand.text1,
                    ),
                  ),
                  if (hasChips) ...[
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _UploadChip(
                          icon: Icons.photo_camera_rounded,
                          label: 'ถ่ายรูป',
                          filled: true,
                          onTap: onCamera!,
                        ),
                        const SizedBox(width: 8),
                        _UploadChip(
                          icon: Icons.image_rounded,
                          label: 'คลังภาพ',
                          filled: false,
                          onTap: onGallery!,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UploadChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback onTap;

  const _UploadChip({
    required this.icon,
    required this.label,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final fg = filled ? Colors.white : brand.text1;
    return Material(
      color: filled ? brand.red : brand.surface,
      shape: StadiumBorder(
        side: BorderSide(color: filled ? brand.red : brand.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 6),
              Text(label, style: AppTypography.label3.copyWith(color: fg)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double strokeWidth;

  _DashedRRectPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final inset = strokeWidth / 2;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        inset,
        inset,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      Radius.circular(radius),
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = color;
    const dash = 5.0;
    const gap = 4.0;
    for (final metric in (Path()..addRRect(rrect)).computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + dash), paint);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRRectPainter old) =>
      old.color != color ||
      old.radius != radius ||
      old.strokeWidth != strokeWidth;
}

// ---------------------------------------------------------------------------
// Info / tips box, banner
// ---------------------------------------------------------------------------

/// Grey tips box with green check bullets.
class RegistrationInfoBox extends StatelessWidget {
  final List<String> lines;
  const RegistrationInfoBox({super.key, required this.lines});

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: brand.fill,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(Icons.check_rounded, size: 15, color: brand.ok),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      line,
                      style: AppTypography.body3.copyWith(
                        color: brand.text2,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Error / locked banner: badBg fill, bad icon + text.
class RegistrationBanner extends StatelessWidget {
  final String message;
  final IconData icon;

  const RegistrationBanner({
    super.key,
    required this.message,
    this.icon = Icons.error_outline_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: brand.badBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: brand.bad),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: brand.bad),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTypography.caption4.copyWith(color: brand.bad),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Result views (success / approved / in review)
// ---------------------------------------------------------------------------

/// Big status circle + title + body, optionally followed by [extra] (e.g.
/// [RegistrationTimeline]).
class RegistrationResultContent extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final bool waiting;
  final Widget? extra;

  const RegistrationResultContent({
    super.key,
    required this.title,
    required this.body,
    this.icon = Icons.task_alt_rounded,
    this.waiting = false,
    this.extra,
  });

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: waiting ? brand.waitBg : brand.okBg,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 44, color: waiting ? brand.wait : brand.ok),
        ),
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppTypography.heading4.copyWith(color: brand.text1),
        ),
        const SizedBox(height: 6),
        Text(
          body,
          textAlign: TextAlign.center,
          style: AppTypography.body2.copyWith(color: brand.text2, height: 1.6),
        ),
        if (extra != null) ...[const SizedBox(height: 16), extra!],
      ],
    );
  }
}

/// ส่งเอกสาร (done) → ตรวจสอบเอกสาร (current) → เริ่มรับงาน (next).
class RegistrationTimeline extends StatelessWidget {
  const RegistrationTimeline({super.key});

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    Widget row(IconData icon, String text, Color color, {bool bold = false}) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 17, color: color),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  text,
                  style: (bold ? AppTypography.label3 : AppTypography.caption5)
                      .copyWith(color: color),
                ),
              ),
            ],
          ),
        );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: brand.fill,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          row(Icons.check_circle_rounded, 'ส่งเอกสาร', brand.ok),
          row(
            Icons.hourglass_top_rounded,
            'ตรวจสอบเอกสาร · 1–2 วันทำการ',
            brand.wait,
            bold: true,
          ),
          row(Icons.radio_button_unchecked_rounded, 'เริ่มรับงาน', brand.text3),
        ],
      ),
    );
  }
}
