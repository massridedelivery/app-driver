import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/theme/app_palette.dart';
import 'package:massdrive/features/history/domain/models/trip_history_rows.dart';
import 'package:massdrive/features/incoming_job/domain/models/offer_headline.dart';
import 'package:massdrive/features/job_live/presentation/widgets/ride_flow_widgets.dart';
import 'package:massdrive/features/next_ride/domain/next_ride.dart';
import 'package:massdrive/features/next_ride/presentation/next_ride_controller.dart';

/// Over the live trip, under the green navigation bar: the next-ride offer
/// card while one waits, else the "งานถัดไป" banner while a ride is queued.
/// Reads GET /jobs/next (and a pending next-ride offer) on entry and when the
/// app comes back to the foreground.
class NextRideOverlay extends ConsumerStatefulWidget {
  const NextRideOverlay({super.key, required this.onTripJobId});

  /// The trip on screen, to recover only an offer made against it.
  final String? onTripJobId;

  @override
  ConsumerState<NextRideOverlay> createState() => _NextRideOverlayState();
}

class _NextRideOverlayState extends ConsumerState<NextRideOverlay>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  void _refresh() {
    if (!mounted) return;
    ref
        .read(nextRideControllerProvider.notifier)
        .refresh(onTripJobId: widget.onTripJobId);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(nextRideControllerProvider);
    final offer = s.offer;
    if (offer != null) {
      return NextRideOfferCard(
        key: ValueKey('next-offer-${offer.jobId}'),
        offer: offer,
        accepting: s.accepting,
      );
    }
    final queued = s.queued;
    if (queued != null) {
      return NextRideBanner(
        key: ValueKey('next-queued-${queued.jobId}'),
        queued: queued,
      );
    }
    return const SizedBox.shrink();
  }
}

/// The compact next-ride offer: "งานถัดไป", the pickup, the two ETAs, the
/// driver's net (or the fare) and the usual countdown, slide and decline.
class NextRideOfferCard extends ConsumerStatefulWidget {
  const NextRideOfferCard({
    super.key,
    required this.offer,
    required this.accepting,
  });

  final NextRideOffer offer;
  final bool accepting;

  @override
  ConsumerState<NextRideOfferCard> createState() => _NextRideOfferCardState();
}

class _NextRideOfferCardState extends ConsumerState<NextRideOfferCard> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    // Repaint the countdown; the controller owns the window itself.
    _tick = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final offer = widget.offer;
    final job = offer.job;
    final p = context.palette;
    final card = RideCardColors.of(context);
    final headline = offerHeadline(
      fare: job.netIncome,
      driverNet: job.driverNet,
    );
    final pay = paymentMethodLabel(job.paymentMethod);
    final controller = ref.read(nextRideControllerProvider.notifier);
    final eta = offer.etaLine;
    return Material(
      color: card.surface,
      elevation: 8,
      shadowColor: Colors.black45,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _NextBadge(text: 'งานถัดไป'),
                      const SizedBox(height: 6),
                      Text(
                        'รับที่ ${job.pickupAddress}',
                        key: const ValueKey('next-offer-pickup'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption3.copyWith(
                          color: p.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                RideOfferMoney(label: headline.label, amount: headline.amount),
              ],
            ),
            if (eta.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                eta,
                key: const ValueKey('next-offer-eta'),
                style: AppTypography.caption5.copyWith(color: p.textSecondary),
              ),
            ],
            if (pay.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                pay,
                style: AppTypography.caption5.copyWith(color: p.textSecondary),
              ),
            ],
            const SizedBox(height: 8),
            RideOfferFooter(
              remaining: offer.remainingAt(DateTime.now()),
              total: offer.totalSeconds,
              autoAccept: false,
              accepting: widget.accepting,
              onAccept: controller.accept,
              onDecline: controller.decline,
            ),
          ],
        ),
      ),
    );
  }
}

/// "งานถัดไป: รับที่ …" while a ride waits for the end of this trip, with
/// "ยกเลิกงานถัดไป" (asks first).
class NextRideBanner extends ConsumerStatefulWidget {
  const NextRideBanner({super.key, required this.queued});

  final QueuedNextRide queued;

  @override
  ConsumerState<NextRideBanner> createState() => _NextRideBannerState();
}

class _NextRideBannerState extends ConsumerState<NextRideBanner> {
  bool _busy = false;

  Future<void> _giveUp() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('ยกเลิกงานถัดไป?'),
        content: const Text(
          'งานนี้จะถูกส่งให้คนขับคนอื่น และจะไม่ถูกเสนอให้คุณอีก',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(d).pop(false),
            child: const Text('ไม่ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.of(d).pop(true),
            child: const Text('ยกเลิกงานถัดไป'),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    setState(() => _busy = true);
    await ref.read(nextRideControllerProvider.notifier).unqueue();
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.queued;
    final p = context.palette;
    final card = RideCardColors.of(context);
    return Material(
      color: card.surface,
      elevation: 6,
      shadowColor: Colors.black38,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        child: Row(
          children: [
            const Icon(
              Icons.playlist_add_check_rounded,
              color: AppColors.foundationMint600,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    q.bannerTitle,
                    key: const ValueKey('next-queued-title'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption4.copyWith(
                      color: p.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    q.arriveByLine ?? 'เริ่มทันทีเมื่อส่งผู้โดยสารเสร็จ',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption5.copyWith(
                      color: p.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: _busy ? null : _giveUp,
              child: Text(
                'ยกเลิกงานถัดไป',
                style: AppTypography.caption5.copyWith(
                  color: AppColors.foundationRed600,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NextBadge extends StatelessWidget {
  const _NextBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.foundationMint600,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: AppTypography.caption5.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
