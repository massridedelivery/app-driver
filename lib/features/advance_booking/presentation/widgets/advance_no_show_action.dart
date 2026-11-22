import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/services/job_cancellation.dart';
import 'package:massdrive/core/theme/app_palette.dart';
import 'package:massdrive/features/advance_booking/domain/advance_errors.dart';
import 'package:massdrive/features/advance_booking/domain/advance_no_show.dart';
import 'package:massdrive/features/advance_booking/presentation/advance_booking_providers.dart';
import 'package:massdrive/features/dependency_injection.dart';
import 'package:massdrive/features/job_live/domain/repositories/job_live_repository.dart';
import 'package:massdrive/features/job_live/domain/services/active_job_resolver.dart';

/// "ลูกค้าไม่มา" on the live ride screen, at the pickup, for a ride booked
/// ahead. Reads the ride's `advance_policy.wait_minutes`, `scheduled_at` and
/// `arrived_at_pickup_at` from GET /api/driver/jobs/active; shows the time it
/// opens while waiting, then the button. The backend enforces the wait (409
/// NO_SHOW_TOO_EARLY). Nothing at all for other rides.
class AdvanceNoShowAction extends ConsumerStatefulWidget {
  const AdvanceNoShowAction({
    super.key,
    required this.jobId,
    required this.isScheduled,
    this.onLayoutChanged,
  });

  final String jobId;

  /// `is_scheduled` / a `scheduled_at`: only such a ride can carry an
  /// advance policy, so other rides never fetch.
  final bool isScheduled;

  /// Called when this grows or changes (rules loaded, the button opening),
  /// so a host that sizes itself to its content re-measures.
  final VoidCallback? onLayoutChanged;

  @override
  ConsumerState<AdvanceNoShowAction> createState() =>
      _AdvanceNoShowActionState();
}

class _AdvanceNoShowActionState extends ConsumerState<AdvanceNoShowAction> {
  AdvanceLiveRide? _ride;

  /// When this screen saw the arrival — used until the server's
  /// `arrived_at_pickup_at` is read.
  final DateTime _arrivedLocally = DateTime.now();
  Timer? _ticker;
  bool _sending = false;
  bool _wasOpen = false;

  bool _isOpen(AdvanceLiveRide ride) =>
      ride.noShowOpenAt(DateTime.now(), arrivedFallback: _arrivedLocally);

  @override
  void initState() {
    super.initState();
    if (widget.isScheduled) _load();
    _ticker = Timer.periodic(const Duration(seconds: 15), (_) {
      final ride = _ride;
      if (!mounted || ride == null) return;
      final open = _isOpen(ride);
      setState(() {});
      if (open != _wasOpen) {
        _wasOpen = open;
        widget.onLayoutChanged?.call();
      }
    });
  }

  @override
  void didUpdateWidget(covariant AdvanceNoShowAction old) {
    super.didUpdateWidget(old);
    if (widget.jobId != old.jobId || (widget.isScheduled && !old.isScheduled)) {
      _ride = null;
      if (widget.isScheduled) _load();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final json = extractJobJson(
        await getIt<JobLiveRepository>().getActiveJob(),
      );
      if (!mounted || json == null) return;
      final ride = AdvanceLiveRide.fromJobJson(json);
      if (ride == null || ride.jobId != widget.jobId) return;
      setState(() {
        _ride = ride;
        _wasOpen = _isOpen(ride);
      });
      widget.onLayoutChanged?.call();
    } catch (e) {
      // No button without the rules; the next arrival re-reads.
      if (kDebugMode) debugPrint('AdvanceNoShowAction: load failed $e');
    }
  }

  Future<void> _report() async {
    final ride = _ride;
    if (ride == null || _sending) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('ผู้โดยสารไม่มาใช่ไหม?'),
        content: Text(
          'คุณรอที่จุดรับครบ ${ride.waitMinutes} นาทีแล้ว งานนี้จะถูกปิด '
          'และลูกค้าจะเสียค่าธรรมเนียมการไม่มาตามนัด '
          'ส่วนแบ่งของคุณจะเข้ากระเป๋าเมื่อเก็บค่าธรรมเนียมจากลูกค้าได้',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(d).pop(false),
            child: const Text('รอต่อ'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(d).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.foundationRed700,
            ),
            child: const Text('ยืนยัน ลูกค้าไม่มา'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _sending = true);
    try {
      await ref.read(advanceBookingApiProvider).noShow(ride.jobId);
      // The app-root listener closes the live screen and tells the driver.
      JobCancellations.instance.report(
        JobCancelEvent(
          ride.jobId,
          message: 'ปิดงานแล้ว เพราะผู้โดยสารไม่มาที่จุดรับ',
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(advanceErrorMessage(e))));
      // Too early by the server's clock: re-read its arrival time.
      if (e is AdvanceBookingException && e.code == 'NO_SHOW_TOO_EARLY') {
        _load();
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ride = _ride;
    if (ride == null) return const SizedBox.shrink();
    if (!_isOpen(ride)) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          ride.waitingHint(arrivedFallback: _arrivedLocally),
          textAlign: TextAlign.center,
          style: AppTypography.caption5.copyWith(
            color: context.palette.textSecondary,
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: OutlinedButton.icon(
        onPressed: _sending ? null : _report,
        icon: _sending
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.person_off_outlined),
        label: const Text('ลูกค้าไม่มา'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.foundationRed700,
          side: const BorderSide(color: AppColors.foundationRed700),
          minimumSize: const Size.fromHeight(44),
        ),
      ),
    );
  }
}
