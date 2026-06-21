import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_routes.dart';
import 'package:massdrive/core/constants/app_spacing.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/features/incoming_job/domain/models/incoming_job_model.dart';
import 'package:massdrive/features/incoming_job/presentation/controllers/incoming_job_controller.dart';

class IncomingJobModal extends ConsumerWidget {
  final IncomingJobModel job;

  const IncomingJobModal({super.key, required this.job});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.semanticGrayNeutralFgMidOnBlack,
        // Dark slightly purplish background from mockup
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

              const SizedBox(height: AppSpacing.s2),
              const Divider(color: Colors.white24, thickness: 1),
              const SizedBox(height: AppSpacing.s2),

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

              const SizedBox(height: AppSpacing.s3),
              const Divider(color: Colors.white24, thickness: 1),
              const SizedBox(height: AppSpacing.s3),

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

              const SizedBox(height: AppSpacing.s5),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        ref
                            .read(incomingJobControllerProvider.notifier)
                            .declineJob();
                        context.go('/');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.semanticSupportRedBgHigh,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.s3,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.s4),
                        ),
                      ),
                      child: Text(
                        'ยกเลิก',
                        style: AppTypography.heading6.copyWith(
                          color: AppColors.semanticGrayNeutralFgWhite,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s3),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        ref
                            .read(incomingJobControllerProvider.notifier)
                            .acceptJob();
                        // Route based on generic service type check
                        final isFood = job.serviceType.toLowerCase().contains(
                          'food',
                        );
                        if (isFood) {
                          context.go(AppRoutes.foodLiveNamedPage);
                        } else {
                          context.go('/job-live');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.semanticSuccessBgHigh,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.s3,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.s4),
                        ),
                      ),
                      child: Text(
                        'รับงาน',
                        style: AppTypography.heading6.copyWith(
                          color: AppColors.semanticGrayNeutralFgWhite,
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
