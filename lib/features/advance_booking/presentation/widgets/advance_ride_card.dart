import 'package:flutter/material.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/theme/app_palette.dart';
import 'package:massdrive/core/utils/baht.dart';
import 'package:massdrive/features/advance_booking/domain/advance_ride.dart';
import 'package:massdrive/features/advance_booking/domain/advance_time.dart';
import 'package:massdrive/features/history/domain/models/trip_history_rows.dart';

/// One ride booked ahead: pickup time (Bangkok), the two addresses, the
/// distances, the estimated net pay, how the customer pays and — at an
/// airport — the flight. Greyed when it clashes with a ride already held.
class AdvanceRideCard extends StatelessWidget {
  const AdvanceRideCard({
    super.key,
    required this.ride,
    required this.now,
    this.footer,
    this.highlighted = false,
  });

  final AdvanceRide ride;
  final DateTime now;

  /// The ride a tapped push is about: an orange frame and a tag.
  final bool highlighted;

  /// Rules lines and buttons under the ride.
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final pay = paymentMethodLabel(ride.paymentMethod);
    final facts = [
      if (ride.distanceKm > 0) 'ระยะทาง ${_km(ride.distanceKm)}',
      if (ride.distanceFromYouKm != null)
        'ห่างคุณ ${_km(ride.distanceFromYouKm!)}',
      if (ride.durationMin > 0) 'ประมาณ ${ride.durationMin.round()} นาที',
    ].join(' · ');
    final card = Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: highlighted
            ? Color.alphaBlend(
                AppColors.foundationOrange700.withValues(alpha: 0.06),
                p.surface,
              )
            : p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlighted ? AppColors.foundationOrange700 : p.border,
          width: highlighted ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (highlighted)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                'งานจากการแจ้งเตือน',
                style: AppTypography.caption5.copyWith(
                  color: AppColors.foundationOrange700,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'รับ ${formatBangkokDayTime(ride.scheduledAt, now)}',
                      style: AppTypography.heading6.copyWith(
                        color: p.textPrimary,
                      ),
                    ),
                    if (ride.vehicleType.isNotEmpty || pay.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          [
                            if (ride.vehicleType.isNotEmpty) ride.vehicleType,
                            if (pay.isNotEmpty) 'ชำระ $pay',
                          ].join(' · '),
                          style: AppTypography.caption5.copyWith(
                            color: p.textSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (ride.earnings != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatBaht(ride.earnings!.net),
                      style: AppTypography.heading5.copyWith(
                        color: AppColors.foundationMint600,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'รายได้สุทธิโดยประมาณ',
                      style: AppTypography.caption5.copyWith(
                        color: p.textSecondary,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          if (ride.flightNumber != null) ...[
            const SizedBox(height: 8),
            _FlightChip(flight: ride.flightNumber!),
          ],
          const SizedBox(height: 10),
          _Stop(
            color: AppColors.foundationMint600,
            label: 'รับ',
            address: ride.pickupAddress,
          ),
          const SizedBox(height: 6),
          _Stop(
            color: AppColors.foundationRed600,
            label: 'ส่ง',
            address: ride.dropoffAddress,
          ),
          if (facts.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              facts,
              style: AppTypography.caption5.copyWith(color: p.textSecondary),
            ),
          ],
          if (ride.conflict) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.event_busy, size: 16, color: p.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'เวลาชนกับงานที่คุณรับไว้แล้ว',
                    style: AppTypography.caption5.copyWith(
                      color: p.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (footer != null) ...[const SizedBox(height: 10), footer!],
        ],
      ),
    );
    return ride.conflict ? Opacity(opacity: 0.5, child: card) : card;
  }

  static String _km(double km) => '${km.toStringAsFixed(1)} กม.';
}

class _Stop extends StatelessWidget {
  const _Stop({
    required this.color,
    required this.label,
    required this.address,
  });

  final Color color;
  final String label;
  final String address;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Icon(Icons.location_on, size: 16, color: color),
        ),
        const SizedBox(width: 6),
        Text(
          '$label  ',
          style: AppTypography.caption4.copyWith(
            color: p.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        Expanded(
          child: Text(
            address.isEmpty ? '-' : address,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption3.copyWith(color: p.textPrimary),
          ),
        ),
      ],
    );
  }
}

class _FlightChip extends StatelessWidget {
  const _FlightChip({required this.flight});

  final String flight;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: p.surfaceAlt,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '✈ รับที่สนามบิน · เที่ยวบิน $flight',
          style: AppTypography.caption4.copyWith(
            color: p.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
