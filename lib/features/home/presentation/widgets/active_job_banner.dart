import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_routes.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/features/dependency_injection.dart';
import 'package:massdrive/features/incoming_job/domain/models/incoming_job_model.dart';
import 'package:massdrive/features/incoming_job/presentation/controllers/incoming_job_controller.dart';
import 'package:massdrive/features/job_live/domain/models/active_item.dart';
import 'package:massdrive/features/job_live/domain/repositories/job_live_repository.dart';
import 'package:massdrive/features/messenger/domain/repositories/messenger_repository.dart';
import 'package:massdrive/features/messenger/presentation/controllers/messenger_controller.dart';

/// Persistent "you have a job in progress" banner shown on Home (SCRUM-45).
/// Probes `GET /api/driver/active`; tap to jump back into the live screen.
class ActiveJobBanner extends ConsumerStatefulWidget {
  const ActiveJobBanner({super.key});

  @override
  ConsumerState<ActiveJobBanner> createState() => _ActiveJobBannerState();
}

class _ActiveJobBannerState extends ConsumerState<ActiveJobBanner> {
  ActiveItem? _item;
  bool _resuming = false;

  @override
  void initState() {
    super.initState();
    _probe();
  }

  Future<void> _probe() async {
    try {
      final active = await getIt<JobLiveRepository>().getActiveSummary();
      if (!mounted) return;
      setState(() => _item = active.isNotEmpty ? active.first : null);
    } catch (_) {
      if (mounted) setState(() => _item = null);
    }
  }

  Map<String, dynamic>? _extractJobJson(dynamic data) {
    if (data is Map<String, dynamic>) {
      final job = data['job'];
      if (job is Map<String, dynamic>) return job;
      return data;
    }
    if (data is List && data.isNotEmpty && data.first is Map<String, dynamic>) {
      return data.first as Map<String, dynamic>;
    }
    return null;
  }

  Future<void> _resume(ActiveItem item) async {
    if (_resuming) return;
    setState(() => _resuming = true);
    try {
      if (item.type == ActiveJobType.messenger) {
        final order = await getIt<MessengerRepository>().getActiveOrder();
        if (order == null) return;
        ref.read(messengerControllerProvider.notifier).setActiveOrder(order);
        if (mounted) context.go('/messenger-live');
        return;
      }

      final repo = getIt<JobLiveRepository>();
      dynamic detail;
      if (item.type == ActiveJobType.ride) {
        detail = await repo.getActiveJob();
      } else if (item.type == ActiveJobType.food) {
        detail = await repo.getActiveFoodOrder();
      } else {
        return;
      }

      final json = _extractJobJson(detail);
      if (json == null) return;
      ref
          .read(incomingJobControllerProvider.notifier)
          .resumeJob(IncomingJobModel.fromJson(json));

      if (!mounted) return;
      if (item.type == ActiveJobType.food) {
        context.go(AppRoutes.foodLiveNamedPage);
      } else {
        context.go('/job-live', extra: item.status);
      }
    } finally {
      if (mounted) setState(() => _resuming = false);
    }
  }

  ({IconData icon, String label}) _display(ActiveJobType type) {
    switch (type) {
      case ActiveJobType.ride:
        return (icon: Icons.local_taxi_rounded, label: 'งานรับส่งผู้โดยสาร');
      case ActiveJobType.food:
        return (icon: Icons.restaurant_rounded, label: 'งานส่งอาหาร');
      case ActiveJobType.messenger:
        return (icon: Icons.local_shipping_rounded, label: 'งานส่งพัสดุ');
      case ActiveJobType.unknown:
        return (icon: Icons.work_rounded, label: 'งานที่กำลังทำ');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Re-probe whenever an offer/active controller changes (accepted, resumed,
    // or completed) so the banner appears and clears in step with the job.
    ref.listen(messengerControllerProvider, (_, _) => _probe());
    ref.listen(incomingJobControllerProvider, (_, _) => _probe());

    final item = _item;
    if (item == null || item.type == ActiveJobType.unknown) {
      return const SizedBox.shrink();
    }
    final display = _display(item.type);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _resuming ? null : () => _resume(item),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.semanticGrayNeutralFgHigh.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.semanticSuccessBgHigh.withValues(alpha: 0.6),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: AppColors.semanticSuccessBgHigh,
                  shape: BoxShape.circle,
                ),
                child: Icon(display.icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'มีงานที่กำลังดำเนินการ',
                      style: AppTypography.caption3.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${display.label} · แตะเพื่อกลับไปที่งาน',
                      style: AppTypography.caption5
                          .copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              _resuming
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.chevron_right, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
