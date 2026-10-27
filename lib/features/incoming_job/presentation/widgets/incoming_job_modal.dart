import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:massdrive/common/widgets/slide_to_confirm.dart';
import 'package:massdrive/core/theme/app_palette.dart';
import 'package:massdrive/features/history/domain/models/trip_history_rows.dart';
import 'package:massdrive/features/job_live/presentation/widgets/ride_flow_widgets.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/features/incoming_job/domain/models/incoming_job_model.dart';
import 'package:massdrive/features/incoming_job/presentation/controllers/incoming_job_controller.dart';
import 'package:massdrive/features/setting/presentation/controllers/auto_accept_controller.dart';
import 'package:massdrive/core/utils/baht.dart';
import 'package:massdrive/features/incoming_job/domain/models/offer_headline.dart';
import 'package:massdrive/features/incoming_job/domain/accept_outcome.dart';

class IncomingJobModal extends ConsumerStatefulWidget {
  final IncomingJobModel job;

  const IncomingJobModal({super.key, required this.job});

  @override
  ConsumerState<IncomingJobModal> createState() => _IncomingJobModalState();
}

class _IncomingJobModalState extends ConsumerState<IncomingJobModal> {
  Timer? _timer;

  /// Total window (seconds) the driver has to accept, from the offer.
  late final int _totalSeconds;

  /// Seconds left on the accept window; drives the button label + progress bar.
  late int _remaining;

  /// Guards against firing accept/decline twice (e.g. tap racing the timeout).
  bool _resolved = false;

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

  bool _accepting = false;

  Future<void> _accept() async {
    if (_resolved) return;
    _resolved = true;
    _timer?.cancel();
    // Disable the buttons until the backend answers (BE #198).
    setState(() => _accepting = true);
    final outcome = await ref
        .read(incomingJobControllerProvider.notifier)
        .acceptJob();
    if (!mounted) return;
    // Failed but not taken: let the driver try again.
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
    ref.read(incomingJobControllerProvider.notifier).declineJob();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    final p = context.palette;
    final card = RideCardColors.of(context);
    final headline = offerHeadline(
      fare: job.netIncome,
      driverNet: job.driverNet,
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
            // Design 2: vehicle + payment · trip km on the left, the driver's
            // net (driver_net — never what the passenger pays) on the right.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RideTag(text: job.serviceType),
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      headline.label,
                      style: AppTypography.caption5.copyWith(
                        color: p.textSecondary,
                      ),
                    ),
                    Text(
                      formatBaht(headline.amount),
                      style: AppTypography.heading2.copyWith(
                        color: AppColors.foundationMint600,
                        fontSize: 32,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Divider(height: 20, color: card.line),
            RideStopsTimeline(
              stops: [
                RideStop(
                  address: job.pickupAddress,
                  sub: '${job.pickupDistanceKm.toStringAsFixed(1)} กม. จากคุณ',
                  isPickup: true,
                  state: RideStopState.current,
                ),
                RideStop(
                  address: job.dropoffAddress,
                  sub: '${tripKm.toStringAsFixed(1)} กม. ทั้งเที่ยว',
                  isPickup: false,
                  state: RideStopState.current,
                ),
              ],
            ),
            // The customer's earlier cancel fee rides on this job (BE PR #15):
            // collected for the company, not the driver's income.
            if (job.priorCancelFeeLine case final line?) ...[
              const SizedBox(height: 8),
              PriorCancelFeeNote(text: line),
            ],
            const SizedBox(height: 6),
            Text(
              autoAccept
                  ? 'รับงานอัตโนมัติใน $_remaining วินาที'
                  : 'ยกเลิกอัตโนมัติใน $_remaining วินาที',
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
                    loading: _accepting,
                    onConfirmed: _accept,
                  ),
                ),
                const SizedBox(width: 10),
                _CountdownRing(remaining: _remaining, total: _totalSeconds),
              ],
            ),
            TextButton(
              onPressed: _accepting ? null : _decline,
              child: Text(
                'ไม่รับงานนี้',
                style: AppTypography.caption3.copyWith(color: p.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Seconds left as a ring that empties; orange for the last 5 s.
class _CountdownRing extends StatelessWidget {
  const _CountdownRing({required this.remaining, required this.total});

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
