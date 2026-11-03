import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/theme/app_palette.dart';
import 'package:massdrive/core/utils/baht.dart';
import 'package:massdrive/features/history/domain/models/trip_history_rows.dart';
import 'package:massdrive/features/incoming_job/domain/accept_outcome.dart';
import 'package:massdrive/features/incoming_job/domain/models/food_order_lines.dart';
import 'package:massdrive/features/incoming_job/domain/models/incoming_job_model.dart';
import 'package:massdrive/features/incoming_job/domain/models/offer_headline.dart';
import 'package:massdrive/features/incoming_job/presentation/controllers/incoming_job_controller.dart';
import 'package:massdrive/features/job_live/presentation/widgets/ride_flow_widgets.dart';
import 'package:massdrive/features/setting/presentation/controllers/auto_accept_controller.dart';

/// Incoming food offer in the ride offer's card ([IncomingJobModal]): tag +
/// payment · km and the money on top, restaurant → customer timeline, the
/// order, and the same accept slide / countdown / decline.
class IncomingFoodModal extends ConsumerStatefulWidget {
  final IncomingJobModel job;

  const IncomingFoodModal({super.key, required this.job});

  @override
  ConsumerState<IncomingFoodModal> createState() => _IncomingFoodModalState();
}

class _IncomingFoodModalState extends ConsumerState<IncomingFoodModal> {
  /// Food lines listed on the card before the rest fold into "อีก N รายการ",
  /// so a big order can't push the accept slide off the screen.
  static const int _maxLines = 4;

  Timer? _timer;

  /// Total window (seconds) the driver has to accept, from the offer.
  late final int _totalSeconds;

  /// Seconds left on the accept window; drives the caption + countdown ring.
  late int _remaining;

  /// Guards against firing accept/decline twice (e.g. tap racing the timeout).
  bool _resolved = false;

  bool _accepting = false;

  @override
  void initState() {
    super.initState();
    // Fixed 16s accept window (the backend sends no timeout_seconds, so this
    // is the app-side source of truth — same value across ride/food/messenger).
    _totalSeconds = widget.job.timeoutSeconds > 0
        ? widget.job.timeoutSeconds
        : 16;
    _remaining = _totalSeconds;
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_remaining <= 1) {
        // Window elapsed. Auto-accept only if the driver opted in; otherwise
        // the offer auto-cancels.
        if (ref.read(autoAcceptProvider)) {
          _accept();
        } else {
          _decline();
        }
      } else {
        setState(() => _remaining--);
      }
    });
  }

  Future<void> _accept() async {
    if (_resolved) return;
    _resolved = true;
    _timer?.cancel();
    // Disable the slide until the backend answers, as on the ride offer.
    setState(() => _accepting = true);
    final outcome = await ref
        .read(incomingJobControllerProvider.notifier)
        .acceptFoodJob();
    if (!mounted) return;
    // Failed but still on offer: let the driver try again.
    if (outcome == AcceptOutcome.failed) {
      setState(() {
        _accepting = false;
        _resolved = false;
      });
    }
  }

  void _decline() {
    if (_resolved) return;
    _resolved = true;
    _timer?.cancel();
    // Food uses the REST reject endpoint (not the ride WS reject_job).
    ref.read(incomingJobControllerProvider.notifier).declineFoodJob();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  IncomingJobModel get job => widget.job;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final card = RideCardColors.of(context);
    final headline = offerHeadline(
      fare: job.netIncome,
      driverNet: job.driverNet,
      delivery: true,
    );
    final autoAccept = ref.watch(autoAcceptProvider);
    final pay = paymentMethodLabel(job.paymentMethod);
    final tripKm = (job.distanceKm ?? 0) > 0
        ? job.distanceKm!
        : job.dropoffDistanceKm;

    return Container(
      decoration: BoxDecoration(
        color: card.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Padding(
        // Bottom inset from viewPadding, not SafeArea: SafeArea reads
        // MediaQuery.padding, which an ancestor can consume to 0 — leaving
        // the accept slide under the system nav/gesture bar.
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          12 + MediaQuery.viewPaddingOf(context).bottom,
        ),
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
                      const RideTag(text: 'ส่งอาหาร'),
                      const SizedBox(height: 4),
                      Text(
                        [
                          if (pay.isNotEmpty) pay,
                          if (tripKm > 0) '${tripKm.toStringAsFixed(1)} กม.',
                        ].join(' · '),
                        style: AppTypography.caption5.copyWith(
                          color: p.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                RideOfferMoney(
                  label: headline.label,
                  amount: headline.amount,
                  note: job.earnings?.commissionLine,
                ),
              ],
            ),
            Divider(height: 20, color: card.line),
            RideStopsTimeline(
              stops: [
                RideStop(
                  address: job.restaurantName ?? job.pickupAddress,
                  sub: [
                    'รับอาหาร',
                    if (job.pickupDistanceKm > 0)
                      '${job.pickupDistanceKm.toStringAsFixed(1)} กม. จากคุณ',
                  ].join(' · '),
                  isPickup: true,
                  state: RideStopState.current,
                ),
                RideStop(
                  address: job.dropoffAddress,
                  sub: [
                    'ส่งอาหาร',
                    if (tripKm > 0) '${tripKm.toStringAsFixed(1)} กม.',
                  ].join(' · '),
                  isPickup: false,
                  state: RideStopState.current,
                ),
              ],
            ),
            const SizedBox(height: 10),
            _orderBox(context),
            const SizedBox(height: 6),
            RideOfferFooter(
              remaining: _remaining,
              total: _totalSeconds,
              autoAccept: autoAccept,
              accepting: _accepting,
              onAccept: _accept,
              onDecline: _decline,
            ),
          ],
        ),
      ),
    );
  }

  /// The order in a soft box: up to [_maxLines] items, then food / delivery
  /// / total.
  Widget _orderBox(BuildContext context) {
    final p = context.palette;
    final lines = FoodOrderLine.listFrom(job.orderItems);
    final totals = FoodOrderTotals.from(
      lines: lines,
      subtotal: job.subtotal,
      deliveryFee: job.deliveryFee,
    );
    final shown = lines.take(_maxLines).toList();
    final hidden = lines.length - shown.length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: RideCardColors.of(context).chip,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (shown.isNotEmpty) ...[
            Text(
              'รายการอาหาร (${lines.length})',
              style: AppTypography.caption5.copyWith(
                color: p.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            for (final line in shown) _itemRow(context, line),
            if (hidden > 0)
              Text(
                'และอีก $hidden รายการ',
                style: AppTypography.caption5.copyWith(color: p.textSecondary),
              ),
            Divider(height: 16, color: RideCardColors.of(context).line),
          ],
          _summaryRow(context, 'ค่าอาหาร', formatBaht(totals.itemsSubtotal)),
          const SizedBox(height: 2),
          _summaryRow(context, 'ค่าส่ง', formatBaht(totals.deliveryFee)),
          const SizedBox(height: 2),
          _summaryRow(
            context,
            'รวมที่ลูกค้าจ่าย',
            formatBaht(totals.total),
            bold: true,
          ),
        ],
      ),
    );
  }

  Widget _itemRow(BuildContext context, FoodOrderLine line) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '${line.qty}x',
              style: AppTypography.caption4.copyWith(
                color: p.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption4.copyWith(color: p.textPrimary),
                ),
                if (line.note != null)
                  Text(
                    line.note!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption5.copyWith(
                      color: p.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            formatBaht(line.lineTotal),
            style: AppTypography.caption4.copyWith(color: p.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(
    BuildContext context,
    String label,
    String value, {
    bool bold = false,
  }) {
    final p = context.palette;
    final style = bold
        ? AppTypography.caption3.copyWith(
            color: p.textPrimary,
            fontWeight: FontWeight.w700,
          )
        : AppTypography.caption5.copyWith(color: p.textSecondary);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value, style: style),
      ],
    );
  }
}
