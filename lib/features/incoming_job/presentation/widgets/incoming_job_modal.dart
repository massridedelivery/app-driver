import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_spacing.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/features/incoming_job/domain/models/incoming_job_model.dart';
import 'package:massdrive/features/incoming_job/presentation/controllers/incoming_job_controller.dart';
import 'package:massdrive/features/setting/presentation/controllers/auto_accept_controller.dart';

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
    _totalSeconds = widget.job.timeoutSeconds > 0
        ? widget.job.timeoutSeconds
        : 15;
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

  void _accept() {
    if (_resolved) return;
    _resolved = true;
    _timer?.cancel();
    ref.read(incomingJobControllerProvider.notifier).acceptJob();
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
    final autoAccept = ref.watch(autoAcceptProvider);
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.semanticGrayNeutralFgMidOnBlack,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppSpacing.s4),
          topRight: Radius.circular(AppSpacing.s4),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s4,
            vertical: AppSpacing.s4,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Section: Income and Points
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          children: [
                            Text(
                              'รายได้สุทธิ',
                              style: AppTypography.body1.copyWith(
                                color: AppColors.semanticGrayNeutralFgWhite,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.s3),
                            Row(
                              children: [
                                Text(
                                  job.netIncome.toInt().toString(),
                                  style: AppTypography.heading2.copyWith(
                                    color: AppColors.semanticGrayNeutralFgWhite,
                                    fontSize: 32,
                                    height: 1.1,
                                  ),
                                ),
                                Text(
                                  ' ฿',
                                  style: AppTypography.caption1.copyWith(
                                    color: AppColors.semanticGrayNeutralFgWhite,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.semanticGrayNeutralFgWhite,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            job.paymentMethod,
                            style: AppTypography.body2.copyWith(
                              color: AppColors.semanticGrayNeutralFgHigh,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.s4),

              // Service Type
              Row(
                children: [
                  const Icon(
                    Icons.inventory_2,
                    color: AppColors.semanticGrayNeutralFgWhite,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    job.serviceType,
                    style: AppTypography.heading5.copyWith(
                      color: AppColors.semanticGrayNeutralFgWhite,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.s4),

              // Timeline
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Timeline Dots & Line
                    Column(
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          decoration: const BoxDecoration(
                            color: AppColors.semanticSuccessBgHigh,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: List.generate(
                                3,
                                (index) => Container(
                                  width: 3,
                                  height: 3,
                                  decoration: const BoxDecoration(
                                    color: Colors.white70,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: 18,
                          height: 18,
                          decoration: const BoxDecoration(
                            color: AppColors.semanticSupportRedBgHigh,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    // Addresses
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildAddressBlock(
                            job.pickupAddress,
                            job.pickupAddressDetail,
                            '${job.pickupDistanceKm} KM',
                          ),
                          const SizedBox(height: 24),
                          _buildAddressBlock(
                            job.dropoffAddress,
                            job.dropoffAddressDetail,
                            '${(job.distanceKm ?? 0.0) > 0 ? job.distanceKm : job.dropoffDistanceKm} KM',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.s4),

              // What happens when the countdown hits 0, driven by the
              // auto-accept preference.
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    autoAccept ? Icons.bolt : Icons.timer_outlined,
                    color: autoAccept
                        ? AppColors.semanticSuccessBgHigh
                        : AppColors.foundationAlphaWhite500,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    autoAccept
                        ? 'รับงานอัตโนมัติใน $_remaining วินาที'
                        : 'ยกเลิกอัตโนมัติใน $_remaining วินาที',
                    style: AppTypography.caption4.copyWith(
                      color: AppColors.foundationAlphaWhite500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s2),

              // Accept window progress bar — depletes as the countdown runs.
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _totalSeconds == 0 ? 0 : _remaining / _totalSeconds,
                  minHeight: 4,
                  backgroundColor: Colors.white12,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _remaining <= 5
                        ? AppColors.semanticSupportRedBgHigh
                        : AppColors.semanticSuccessBgHigh,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.s3),

              // Action Buttons — large, thumb-friendly pills.
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 60,
                      child: ElevatedButton(
                        onPressed: _decline,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.semanticSupportRedBgHigh,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.s5),
                          ),
                        ),
                        child: Text(
                          'ยกเลิก',
                          style: AppTypography.heading5.copyWith(
                            color: AppColors.semanticGrayNeutralFgWhite,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s3),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 60,
                      child: ElevatedButton(
                        onPressed: _accept,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.semanticSuccessBgHigh,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.s5),
                          ),
                        ),
                        child: Text(
                          'รับงาน ($_remaining)',
                          style: AppTypography.heading5.copyWith(
                            color: AppColors.semanticGrayNeutralFgWhite,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddressBlock(String title, String detail, String distance) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                title,
                style: AppTypography.heading5.copyWith(
                  color: AppColors.semanticGrayNeutralFgWhite,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: 8),
            Text(
              distance,
              style: AppTypography.caption4.copyWith(
                color: AppColors.foundationAlphaWhite500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
