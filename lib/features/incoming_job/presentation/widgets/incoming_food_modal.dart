import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_routes.dart';
import 'package:massdrive/core/constants/app_spacing.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/features/incoming_job/domain/models/incoming_job_model.dart';
import 'package:massdrive/features/incoming_job/presentation/controllers/incoming_job_controller.dart';

class IncomingFoodModal extends ConsumerWidget {
  final IncomingJobModel job;

  const IncomingFoodModal({super.key, required this.job});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.semanticGrayNeutralFgMidOnBlack,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppSpacing.s6),
          topRight: Radius.circular(AppSpacing.s6),
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
              // Header: MassFood badge + income
              _buildHeader(),
              const SizedBox(height: AppSpacing.s3),
              const Divider(color: Colors.white24, thickness: 1),
              const SizedBox(height: AppSpacing.s3),

              // Restaurant name
              _buildRestaurantInfo(),
              const SizedBox(height: AppSpacing.s3),

              // Order items
              if (job.orderItems.isNotEmpty) ...[
                _buildOrderItems(),
                const SizedBox(height: AppSpacing.s3),
              ],

              // Delivery route
              _buildDeliveryRoute(),
              const SizedBox(height: AppSpacing.s3),

              // Order summary
              _buildOrderSummary(),
              const SizedBox(height: AppSpacing.s5),

              // Action Buttons
              _buildActionButtons(context, ref),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Food icon badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.foundationOrange600,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.fastfood, color: Colors.white, size: 16),
              const SizedBox(width: 4),
              Text(
                'MassFood',
                style: AppTypography.label3.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
        const Spacer(),
        // Net income
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'รายได้สุทธิ',
              style: AppTypography.caption5.copyWith(color: Colors.white70),
            ),
            Row(
              children: [
                Text(
                  job.netIncome.toInt().toString(),
                  style: AppTypography.heading2.copyWith(
                    color: AppColors.semanticGrayNeutralFgWhite,
                    fontSize: 28,
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
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.semanticGrayNeutralFgWhite,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            job.paymentMethod,
            style: AppTypography.body3.copyWith(
              color: AppColors.semanticGrayNeutralFgHigh,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRestaurantInfo() {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.foundationOrange100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.storefront,
            color: AppColors.foundationOrange600,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                job.restaurantName ?? 'ร้านอาหาร',
                style: AppTypography.heading6.copyWith(
                  color: AppColors.semanticGrayNeutralFgWhite,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                job.pickupAddress,
                style: AppTypography.caption5.copyWith(color: Colors.white54),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrderItems() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'รายการอาหาร',
            style: AppTypography.caption5.copyWith(
              color: AppColors.foundationOrange500,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...job.orderItems.map((item) {
            final name = item['name'] ?? '';
            final qty = item['qty'] ?? 1;
            final price = (item['price'] as num?)?.toDouble() ?? 0.0;
            final note = item['note'] as String?;

            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: AppColors.foundationOrange600,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${qty}x',
                      style: AppTypography.support1.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: AppTypography.caption4.copyWith(
                            color: AppColors.semanticGrayNeutralFgWhite,
                          ),
                        ),
                        if (note != null && note.isNotEmpty)
                          Text(
                            note,
                            style: AppTypography.caption5.copyWith(
                              color: Colors.white38,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    '฿${price.toStringAsFixed(0)}',
                    style: AppTypography.caption4.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDeliveryRoute() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline dots
          Column(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: AppColors.foundationOrange600,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.storefront, size: 10, color: Colors.white),
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
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: AppColors.semanticSuccessBgHigh,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.location_on, size: 10, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // Addresses
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.pickupAddress,
                  style: AppTypography.caption4.copyWith(
                    color: AppColors.semanticGrayNeutralFgWhite,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 20),
                Text(
                  job.dropoffAddress,
                  style: AppTypography.caption4.copyWith(
                    color: AppColors.semanticGrayNeutralFgWhite,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    final subtotal = job.subtotal > 0
        ? job.subtotal
        : job.orderItems.fold<double>(
            0,
            (sum, item) =>
                sum +
                ((item['price'] as num?)?.toDouble() ?? 0) *
                    ((item['qty'] as int?) ?? 1),
          );
    final deliveryFee = job.deliveryFee;
    final total = subtotal + deliveryFee;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _summaryRow('ค่าอาหาร', '฿${subtotal.toStringAsFixed(0)}'),
          const SizedBox(height: 4),
          _summaryRow('ค่าส่ง', '฿${deliveryFee.toStringAsFixed(0)}'),
          const Divider(color: Colors.white12, height: 16),
          _summaryRow(
            'รวม',
            '฿${total.toStringAsFixed(0)}',
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isBold = false}) {
    final style = isBold
        ? AppTypography.heading6.copyWith(
            color: AppColors.semanticGrayNeutralFgWhite,
          )
        : AppTypography.caption5.copyWith(color: Colors.white54);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value, style: style),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref) {
    return Row(
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
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.s3),
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
                  .acceptFoodJob();
              context.go(AppRoutes.foodLiveNamedPage);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.foundationOrange600,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.s3),
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
    );
  }
}
