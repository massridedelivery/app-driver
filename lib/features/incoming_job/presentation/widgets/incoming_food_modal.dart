import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:massdrive/common/widgets/job_offer_action_bar.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_spacing.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/features/incoming_job/domain/models/incoming_job_model.dart';
import 'package:massdrive/features/incoming_job/presentation/controllers/incoming_job_controller.dart';
import 'package:massdrive/features/setting/presentation/controllers/auto_accept_controller.dart';

class IncomingFoodModal extends ConsumerStatefulWidget {
  final IncomingJobModel job;

  const IncomingFoodModal({super.key, required this.job});

  @override
  ConsumerState<IncomingFoodModal> createState() => _IncomingFoodModalState();
}

class _IncomingFoodModalState extends ConsumerState<IncomingFoodModal> {
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
    ref.read(incomingJobControllerProvider.notifier).acceptFoodJob();
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
    final autoAccept = ref.watch(autoAcceptProvider);
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
        bottom: false,
        child: Padding(
          // Bottom inset from viewPadding, not SafeArea: SafeArea reads
          // MediaQuery.padding, which an ancestor can consume to 0 — leaving
          // the accept button under the system nav/gesture bar.
          padding: EdgeInsets.fromLTRB(
            AppSpacing.s4,
            AppSpacing.s4,
            AppSpacing.s4,
            AppSpacing.s4 + MediaQuery.viewPaddingOf(context).bottom,
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
              const SizedBox(height: AppSpacing.s4),

              // Shared accept/decline footer: auto-accept caption, progress bar
              // and the large cancel/accept pills — same flow as the ride offer.
              JobOfferActionBar(
                remaining: _remaining,
                totalSeconds: _totalSeconds,
                autoAccept: autoAccept,
                onAccept: _accept,
                onDecline: _decline,
              ),
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
        color: Colors.white.withValues(alpha: 0.05),
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
        color: Colors.white.withValues(alpha: 0.05),
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
}
