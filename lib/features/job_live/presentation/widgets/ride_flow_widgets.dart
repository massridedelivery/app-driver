import 'package:flutter/material.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/theme/app_palette.dart';

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

/// Pickup → dropoff with a line between; the stop being driven to stands
/// out, a passed one is faded with ✓.
class RideStopsTimeline extends StatelessWidget {
  const RideStopsTimeline({super.key, required this.stops});

  final List<RideStop> stops;

  @override
  Widget build(BuildContext context) {
    final line = RideCardColors.of(context).line;
    return Stack(
      children: [
        Positioned(
          left: 6,
          top: 16,
          bottom: 16,
          child: Container(width: 2, color: line),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [for (final s in stops) _stop(context, s)],
        ),
      ],
    );
  }

  Widget _stop(BuildContext context, RideStop s) {
    final p = context.palette;
    final color = s.isPickup
        ? AppColors.foundationMint600
        : AppColors.semanticSupportRedBgHigh;
    final opacity = switch (s.state) {
      RideStopState.current => 1.0,
      RideStopState.upcoming => 0.6,
      RideStopState.done => 0.5,
    };
    return Opacity(
      opacity: opacity,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 14,
              height: 14,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: RideCardColors.of(context).surface,
                  width: 2,
                ),
              ),
              child: s.state == RideStopState.done
                  ? const Icon(Icons.check, size: 8, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                      style: AppTypography.caption5.copyWith(
                        color: p.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
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
