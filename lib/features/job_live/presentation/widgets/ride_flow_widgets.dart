import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:massdrive/common/widgets/slide_to_confirm.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/theme/app_palette.dart';
import 'package:massdrive/core/utils/baht.dart';

/// Ride-flow card colours: white in light mode, the job-card dark surface in
/// dark mode.
class RideCardColors {
  const RideCardColors._(this.surface, this.chip, this.line);

  final Color surface;
  final Color chip;
  final Color line;

  static RideCardColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const RideCardColors._(
          Color(0xFF262932),
          Color(0x1AFFFFFF),
          Color(0x1FFFFFFF),
        )
      : const RideCardColors._(
          Colors.white,
          Color(0xFFF1F5F9),
          Color(0xFFE5E7EB),
        );
}

/// Green navigation bar at the top of the live ride: "1 · ไปรับ", the address
/// heading to, the distance (or a status such as "รอผู้โดยสาร") and นำทาง.
class RideNavBanner extends StatelessWidget {
  const RideNavBanner({
    super.key,
    required this.step,
    required this.address,
    required this.headline,
    required this.onNavigate,
  });

  final String step;
  final String address;

  /// "600 ม." / "3.2 กม." / "รอผู้โดยสาร"; empty hides the line's text.
  final String headline;
  final VoidCallback onNavigate;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.foundationMint600,
      elevation: 6,
      shadowColor: Colors.black45,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              step,
              style: AppTypography.caption5.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              address,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.label2.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    headline,
                    style: AppTypography.heading5.copyWith(color: Colors.white),
                  ),
                ),
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: onNavigate,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.navigation_rounded,
                            size: 16,
                            color: AppColors.foundationMint600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'นำทาง',
                            style: AppTypography.caption4.copyWith(
                              color: AppColors.foundationMint600,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Small grey pill: "มอเตอร์ไซค์ · เงินสด".
class RideTag extends StatelessWidget {
  const RideTag({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: RideCardColors.of(context).chip,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      text,
      style: AppTypography.caption5.copyWith(
        color: context.palette.textPrimary,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

/// How a stop reads on the timeline.
enum RideStopState { upcoming, current, done }

/// One stop: pickup (green) or dropoff (red), its address and a sub-line.
class RideStop {
  const RideStop({
    required this.address,
    required this.sub,
    required this.isPickup,
    this.state = RideStopState.upcoming,
  });

  final String address;
  final String sub;
  final bool isPickup;
  final RideStopState state;
}

/// Pickup → dropoff like the customer app's RouteStops: a green / red map
/// pin with a dotted connector running from the green pin down to the red
/// one. The stop being driven to stands out; a passed stop is faded with ✓.
class RideStopsTimeline extends StatelessWidget {
  const RideStopsTimeline({super.key, required this.stops, this.pinSize = 20});

  final List<RideStop> stops;
  final double pinSize;

  static const pinAsset = 'assets/images/icons/ic_location_fill.svg';
  static const pickupColor = Color(0xFF2EB610);
  static const dropoffColor = Color(0xFFDB1439);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < stops.length; i++)
          i < stops.length - 1
              // Intrinsic height so the dots fill from under this pin to the
              // next stop's pin — one continuous connector.
              ? IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: pinSize,
                        child: Column(
                          children: [
                            _pin(stops[i]),
                            const SizedBox(height: 2),
                            Expanded(
                              child: SizedBox(
                                width: 4,
                                child: CustomPaint(
                                  painter: _DottedLinePainter(
                                    context.palette.textTertiary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _text(context, stops[i]),
                        ),
                      ),
                    ],
                  ),
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _pin(stops[i]),
                    const SizedBox(width: 12),
                    Expanded(child: _text(context, stops[i])),
                  ],
                ),
      ],
    );
  }

  double _opacity(RideStop s) => switch (s.state) {
    RideStopState.current => 1.0,
    RideStopState.upcoming => 0.6,
    RideStopState.done => 0.45,
  };

  Widget _pin(RideStop s) => Opacity(
    opacity: _opacity(s),
    child: SvgPicture.asset(
      pinAsset,
      width: pinSize,
      height: pinSize,
      colorFilter: ColorFilter.mode(
        s.isPickup ? pickupColor : dropoffColor,
        BlendMode.srcIn,
      ),
    ),
  );

  Widget _text(BuildContext context, RideStop s) {
    final p = context.palette;
    return Opacity(
      opacity: _opacity(s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                s.isPickup ? 'จุดรับ' : 'จุดส่ง',
                style: AppTypography.caption5.copyWith(
                  color: p.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (s.state == RideStopState.done) ...[
                const SizedBox(width: 4),
                const Icon(Icons.check_circle, size: 12, color: pickupColor),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(
            s.address,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption3.copyWith(
              color: p.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (s.sub.isNotEmpty)
            Text(
              s.sub,
              style: AppTypography.caption5.copyWith(color: p.textSecondary),
            ),
        ],
      ),
    );
  }
}

/// Round dots (not dashes), 3 px with an 11 px pitch — the customer app's
/// route connector.
class _DottedLinePainter extends CustomPainter {
  const _DottedLinePainter(this.color);

  final Color color;

  static const double _radius = 1.5;
  static const double _pitch = 11;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.height <= 2 * _radius) return;
    final paint = Paint()..color = color;
    final x = size.width / 2;
    final count = ((size.height - 2 * _radius) / _pitch).floor() + 1;
    final span = (count - 1) * _pitch;
    var y = (size.height - span) / 2;
    for (var i = 0; i < count; i++) {
      canvas.drawCircle(Offset(x, y), _radius, paint);
      y += _pitch;
    }
  }

  @override
  bool shouldRepaint(_DottedLinePainter old) => old.color != color;
}

/// Round grey icon button on the card (แชท / โทรฟรี / ช่วยเหลือ).
class RideIconButton extends StatelessWidget {
  const RideIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: Material(
      color: RideCardColors.of(context).chip,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            icon,
            size: 20,
            color: onTap == null
                ? context.palette.textTertiary
                : context.palette.textPrimary,
          ),
        ),
      ),
    ),
  );
}

/// The money on an offer card, right-aligned: "รายได้สุทธิ" over the big
/// green figure.
class RideOfferMoney extends StatelessWidget {
  const RideOfferMoney({super.key, required this.label, required this.amount});

  final String label;
  final double amount;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: AppTypography.caption5.copyWith(color: p.textSecondary),
        ),
        Text(
          formatBaht(amount),
          style: AppTypography.heading2.copyWith(
            color: AppColors.foundationMint600,
            fontSize: 32,
            height: 1.1,
          ),
        ),
      ],
    );
  }
}

/// "ค่ายกเลิกครั้งก่อนของลูกค้า ฿X (เก็บแทนบริษัท)" on the offer and the
/// collect screen: money taken for the company on top of this job's fare.
class PriorCancelFeeNote extends StatelessWidget {
  const PriorCancelFeeNote({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.foundationOrange500.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: AppColors.foundationOrange500,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTypography.caption3.copyWith(
                color: context.palette.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The driver's money on the live card as a solid green pill — the only
/// green in the stop box, so it stands out.
class RideNetPill extends StatelessWidget {
  const RideNetPill({super.key, required this.amount});

  final double amount;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
    decoration: BoxDecoration(
      color: AppColors.foundationMint600,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      formatBaht(amount),
      style: AppTypography.heading4.copyWith(color: Colors.white),
    ),
  );
}

/// The stop being driven to, big: "กำลังไป · จุดรับ" with the money pill on
/// top, then the pin, the address (full width) and a facts line.
class RideNextStopCard extends StatelessWidget {
  const RideNextStopCard({
    super.key,
    required this.label,
    required this.amount,
    required this.address,
    required this.toDropoff,
    this.facts = '',
  });

  final String label;
  final double amount;
  final String address;
  final bool toDropoff;

  /// "600 ม. · 2 นาที" / "พัสดุ S · 1 กก."; empty hides the line.
  final String facts;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: RideCardColors.of(context).chip,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.caption5.copyWith(
                    color: p.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              RideNetPill(amount: amount),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SvgPicture.asset(
                RideStopsTimeline.pinAsset,
                width: 22,
                height: 22,
                colorFilter: ColorFilter.mode(
                  toDropoff
                      ? RideStopsTimeline.dropoffColor
                      : RideStopsTimeline.pickupColor,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      address,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.label2.copyWith(
                        color: p.textPrimary,
                      ),
                    ),
                    if (facts.isNotEmpty)
                      Text(
                        facts,
                        style: AppTypography.caption5.copyWith(
                          color: p.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One line about the other stop under [RideNextStopCard]: "จากนั้นส่งที่ …"
/// before pickup, "รับแล้ว · …" on the way to the dropoff.
class RideThenLine extends StatelessWidget {
  const RideThenLine({super.key, required this.text, required this.toDropoff});

  final String text;

  /// Heading to the dropoff: the other stop is the (green) pickup.
  final bool toDropoff;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const SizedBox(width: 4),
      SvgPicture.asset(
        RideStopsTimeline.pinAsset,
        width: 14,
        height: 14,
        colorFilter: ColorFilter.mode(
          toDropoff
              ? RideStopsTimeline.pickupColor
              : RideStopsTimeline.dropoffColor,
          BlendMode.srcIn,
        ),
      ),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.caption5.copyWith(
            color: context.palette.textSecondary,
          ),
        ),
      ),
    ],
  );
}

/// Seconds left on an offer as a ring that empties; orange for the last 5 s.
class RideCountdownRing extends StatelessWidget {
  const RideCountdownRing({
    super.key,
    required this.remaining,
    required this.total,
  });

  final int remaining;
  final int total;

  @override
  Widget build(BuildContext context) {
    final color = remaining <= 5
        ? AppColors.foundationOrange700
        : AppColors.foundationMint600;
    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: total <= 0 ? 0 : remaining / total,
            strokeWidth: 3,
            color: color,
            backgroundColor: RideCardColors.of(context).line,
          ),
          Text(
            '$remaining',
            style: AppTypography.caption3.copyWith(
              color: context.palette.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// The bottom of an offer card: "ยกเลิก/รับงานอัตโนมัติใน N วินาที", the
/// accept slide with its countdown ring, and "ไม่รับงานนี้".
class RideOfferFooter extends StatelessWidget {
  const RideOfferFooter({
    super.key,
    required this.remaining,
    required this.total,
    required this.autoAccept,
    required this.accepting,
    required this.onAccept,
    required this.onDecline,
  });

  final int remaining;
  final int total;
  final bool autoAccept;
  final bool accepting;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          autoAccept
              ? 'รับงานอัตโนมัติใน $remaining วินาที'
              : 'ยกเลิกอัตโนมัติใน $remaining วินาที',
          textAlign: TextAlign.center,
          style: AppTypography.caption5.copyWith(color: p.textSecondary),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: SlideToConfirm(
                label: 'เลื่อนเพื่อรับงาน',
                color: AppColors.foundationMint600,
                loading: accepting,
                onConfirmed: onAccept,
              ),
            ),
            const SizedBox(width: 10),
            RideCountdownRing(remaining: remaining, total: total),
          ],
        ),
        TextButton(
          onPressed: accepting ? null : onDecline,
          child: Text(
            'ไม่รับงานนี้',
            style: AppTypography.caption3.copyWith(color: p.textSecondary),
          ),
        ),
      ],
    );
  }
}
