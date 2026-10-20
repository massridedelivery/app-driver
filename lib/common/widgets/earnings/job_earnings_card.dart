import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/theme/app_palette.dart';
import 'package:massdrive/core/utils/baht.dart';
import 'package:massdrive/features/history/domain/models/service_icon.dart';

/// Job-card palette (design 5, "รายได้สีเขียว"): a green-tinted card where
/// the net reads green = money in. Light and dark variants.
class _CardColors {
  const _CardColors({
    required this.bg,
    required this.border,
    required this.title,
    required this.subtitle,
    required this.label,
    required this.credit,
    required this.debit,
    required this.divider,
    required this.net,
  });

  final Color bg;
  final Color border;
  final Color title;
  final Color subtitle;
  final Color label;
  final Color credit;
  final Color debit;
  final Color divider;
  final Color net;

  static const dark = _CardColors(
    bg: Color(0xFF1F2A27),
    border: Color(0xFF234A3C),
    title: Color(0xFFF0FDF4),
    subtitle: Color(0xFF86A99B),
    label: Color(0xFFA7C4B8),
    credit: Color(0xFFA7F3D0),
    debit: Color(0xFFFCA5A5),
    divider: Color(0xFF2F4A40),
    net: Color(0xFF4ADE80),
  );

  static const light = _CardColors(
    bg: Color(0xFFF0FDF4),
    border: Color(0xFFBBF7D0),
    title: Color(0xFF052E16),
    subtitle: Color(0xFF4B7C6B),
    label: Color(0xFF3F6B5C),
    credit: Color(0xFF047857),
    debit: Color(0xFFB91C1C),
    divider: Color(0xFFBBF7D0),
    net: Color(0xFF15803D),
  );

  static _CardColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

/// One money movement on a job card ("ค่าโดยสาร +฿2").
class JobCardLine {
  const JobCardLine({required this.label, required this.amount, this.badge});

  final String label;
  final double amount;

  /// Shown before the amount when the movement needs attention (pending…).
  final Widget? badge;
}

/// The receipt layout's extras (design 4, ประวัติการให้บริการ): the sub-line
/// shows "เวลา · กม. · วิธีจ่าย" instead of the pickup, a status chip sits on
/// the right and dashed rules frame the money lines.
class JobReceiptInfo {
  const JobReceiptInfo({
    this.distanceKm,
    this.paymentLabel,
    this.statusLabel = 'สำเร็จ',
    this.statusOk = true,
  });

  final double? distanceKm;
  final String? paymentLabel;
  final String statusLabel;

  /// Green chip when true (completed), red otherwise (cancelled…).
  final bool statusOk;
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
    this.receipt,
  });

  /// Set → receipt layout (ประวัติการให้บริการ); null → the statement card.
  final JobReceiptInfo? receipt;

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
    final c = _CardColors.of(context);
    final r = receipt;
    final subLine = r != null
        ? [
            clock,
            if (r.distanceKm != null) '${r.distanceKm!.toStringAsFixed(1)} กม.',
            if ((r.paymentLabel ?? '').isNotEmpty) r.paymentLabel!,
          ].join(' · ')
        : (pickup == null || pickup.isEmpty)
        ? clock
        : '$clock · $pickup';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Material(
        color: c.bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: c.border),
        ),
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
                              color: c.title,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subLine,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption5.copyWith(
                              color: c.subtitle,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (r != null) _statusChip(r),
                  ],
                ),
                if (r != null)
                  _DashedRule(color: c.divider)
                else
                  const SizedBox(height: 8),
                for (final l in lines) _line(l, c),
                if (r != null)
                  _DashedRule(color: c.divider)
                else
                  Divider(color: c.divider, height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'รายได้สุทธิ',
                      style: AppTypography.caption3.copyWith(
                        color: c.title,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      driverNet == null
                          ? 'รอสรุปยอด'
                          : formatBaht(driverNet!.toDouble()),
                      style: AppTypography.heading5.copyWith(
                        color: c.net,
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

  Widget _statusChip(JobReceiptInfo r) {
    final fg = r.statusOk ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5);
    final bg = r.statusOk ? const Color(0xFF14532D) : const Color(0xFF7F1D1D);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        r.statusLabel,
        style: AppTypography.caption5.copyWith(color: fg),
      ),
    );
  }

  Widget _line(JobCardLine l, _CardColors c) {
    final color = l.amount >= 0 ? c.credit : c.debit;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l.label,
              style: AppTypography.caption5.copyWith(color: c.label),
            ),
          ),
          if (l.badge != null) ...[l.badge!, const SizedBox(width: 6)],
          Text(
            formatSignedBaht(l.amount, plus: true),
            style: AppTypography.caption5.copyWith(color: color),
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

/// A dashed horizontal rule — the receipt's tear lines.
class _DashedRule extends StatelessWidget {
  const _DashedRule({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: LayoutBuilder(
      builder: (_, box) {
        const dash = 5.0, gap = 4.0;
        final n = (box.maxWidth / (dash + gap)).floor();
        return Row(
          children: [
            for (var i = 0; i < n; i++) ...[
              Container(width: dash, height: 1, color: color),
              const SizedBox(width: gap),
            ],
          ],
        );
      },
    ),
  );
}
