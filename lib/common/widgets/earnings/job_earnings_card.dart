import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/theme/app_palette.dart';
import 'package:massdrive/core/utils/baht.dart';
import 'package:massdrive/features/history/domain/models/service_icon.dart';

/// One money movement on a job card ("ค่าโดยสาร +฿2").
class JobCardLine {
  const JobCardLine({required this.label, required this.amount, this.badge});

  final String label;
  final double amount;

  /// Shown before the amount when the movement needs attention (pending…).
  final Widget? badge;
}

/// Everything one job moved, as one card (design E): the vehicle on its own
/// (Mass 3D icon, no frame) + Thai type and short job id, time · pickup, each
/// movement with its signed amount, and รายได้สุทธิ from the backend's
/// whole-baht `driver_net` — "รอสรุปยอด" until it settles, never summed here.
/// Used by รายการทั้งหมด and ประวัติการให้บริการ.
class JobEarningsCard extends StatelessWidget {
  const JobEarningsCard({
    super.key,
    required this.jobId,
    required this.time,
    required this.lines,
    this.service,
    this.vehicleTypeName,
    this.pickupAddress,
    this.driverNet,
    this.onTap,
  });

  final String jobId;
  final DateTime time;
  final List<JobCardLine> lines;
  final String? service;
  final String? vehicleTypeName;
  final String? pickupAddress;
  final int? driverNet;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final shortId = jobId.length > 6 ? jobId.substring(0, 6) : jobId;
    final clock = DateFormat('HH:mm').format(time.toLocal());
    final pickup = pickupAddress?.trim();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Material(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Image.asset(
                      serviceIconAsset(
                        service: service,
                        vehicleTypeName: vehicleTypeName,
                      ),
                      width: 40,
                      height: 40,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${serviceLabel(service: service, vehicleTypeName: vehicleTypeName)} · งาน #$shortId',
                            style: AppTypography.caption3.copyWith(
                              color: context.palette.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            (pickup == null || pickup.isEmpty)
                                ? clock
                                : '$clock · $pickup',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption5.copyWith(
                              color: context.palette.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                for (final l in lines) _line(context, l),
                Divider(color: context.palette.border, height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'รายได้สุทธิ',
                      style: AppTypography.caption3.copyWith(
                        color: context.palette.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      driverNet == null
                          ? 'รอสรุปยอด'
                          : formatBaht(driverNet!.toDouble()),
                      style: AppTypography.caption3.copyWith(
                        color: AppColors.foundationOrange600,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _line(BuildContext context, JobCardLine l) {
    final color = l.amount >= 0
        ? AppColors.semanticSupportMintBgHigh
        : AppColors.semanticErrorFgHigh;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l.label,
              style: AppTypography.caption4.copyWith(
                color: context.palette.textSecondary,
              ),
            ),
          ),
          if (l.badge != null) ...[l.badge!, const SizedBox(width: 6)],
          Text(
            formatSignedBaht(l.amount, plus: true),
            style: AppTypography.caption4.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

/// Day header of an earnings list — "19 กันยายน 2026" (Thai month,
/// Gregorian year to match the row timestamps).
class EarningsDayHeader extends StatelessWidget {
  const EarningsDayHeader({super.key, required this.date});

  final DateTime date;

  static const _thMonths = [
    'มกราคม',
    'กุมภาพันธ์',
    'มีนาคม',
    'เมษายน',
    'พฤษภาคม',
    'มิถุนายน',
    'กรกฎาคม',
    'สิงหาคม',
    'กันยายน',
    'ตุลาคม',
    'พฤศจิกายน',
    'ธันวาคม',
  ];

  @override
  Widget build(BuildContext context) {
    final label = '${date.day} ${_thMonths[date.month - 1]} ${date.year}';
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 4),
      child: Text(
        label,
        style: AppTypography.caption5.copyWith(
          color: context.palette.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
