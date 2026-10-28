import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/theme/app_palette.dart';
import 'package:massdrive/core/utils/baht.dart';
import 'package:massdrive/features/history/domain/models/service_icon.dart';

/// Job-card palette (design 3): a plain card in the theme's surface colour,
/// a thin status bar on the left, and only the net (and the bar) in green.
/// Light and dark variants.
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
    required this.cancelled,
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

  /// Status bar / chip of a cancelled job.
  final Color cancelled;

  static const dark = _CardColors(
    bg: Color(0xFF1E2026),
    border: Color(0x1AFFFFFF),
    title: Colors.white,
    subtitle: Color(0x99FFFFFF),
    label: Color(0xC7FFFFFF),
    credit: Color(0xFFE6E8EE),
    debit: Color(0xFFFF8A8A),
    divider: Color(0x24FFFFFF),
    net: Color(0xFF3DDC84),
    cancelled: Color(0xFFFF6B6B),
  );

  static const light = _CardColors(
    bg: Colors.white,
    border: Color(0xFFE7E9EE),
    title: Color(0xFF1B1D22),
    subtitle: Color(0xFF6B7280),
    label: Color(0xFF334155),
    credit: Color(0xFF0F172A),
    debit: Color(0xFFDC2626),
    divider: Color(0xFFE7E9EE),
    net: Color(0xFF0D995C),
    cancelled: Color(0xFFDC2626),
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

/// The receipt layout's extras (ประวัติการให้บริการ): the sub-line shows
/// "เวลา · กม. · วิธีจ่าย" instead of the pickup, the status bar follows the
/// job's status and a cancelled job also gets a "ยกเลิก" chip.
class JobReceiptInfo {
  const JobReceiptInfo({
    this.distanceKm,
    this.paymentLabel,
    this.statusLabel = 'สำเร็จ',
    this.statusOk = true,
    this.discount,
    this.paidInCash = true,
    this.customerPaid,
    this.cashCollected,
    this.walletCredit,
  });

  final double? distanceKm;
  final String? paymentLabel;
  final String statusLabel;

  /// Green bar when true (completed); red bar + chip otherwise (cancelled…).
  final bool statusOk;

  /// "ลูกค้าชำระ" block, shown only when a promo was applied. Figures come
  /// from the backend as-is: the discount (platform-funded), what the
  /// customer paid, the cash the driver took, and what the trip moved in the
  /// wallet. A null figure is simply not shown.
  final double? discount;
  final bool paidInCash;
  final double? customerPaid;
  final double? cashCollected;
  final double? walletCredit;

  bool get hasPromo => (discount ?? 0) > 0;
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

    final ok = r?.statusOk ?? true;
    final radius = BorderRadius.circular(12);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Material(
        color: c.bg,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: c.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 14, 12),
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
                        if (r != null && !r.statusOk) _statusChip(r, c),
                      ],
                    ),
                    _DashedRule(color: c.divider),
                    for (final l in lines) _line(l, c),
                    const SizedBox(height: 6),
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
                    // How the customer paid — information only, it doesn't
                    // change รายได้สุทธิ (promos are platform-funded).
                    if (r != null && r.hasPromo) ..._customerPaidBlock(r, c),
                  ],
                ),
              ),
              // Status bar: green = completed, red = cancelled.
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(width: 4, color: ok ? c.net : c.cancelled),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _customerPaidBlock(JobReceiptInfo r, _CardColors c) {
    Widget row(String label, String value, {Color? color}) => Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.caption5.copyWith(color: c.subtitle),
            ),
          ),
          Text(
            value,
            style: AppTypography.caption5.copyWith(color: color ?? c.subtitle),
          ),
        ],
      ),
    );
    final wallet = r.walletCredit;
    return [
      _DashedRule(color: c.divider),
      Text(
        'ลูกค้าชำระ',
        style: AppTypography.caption4.copyWith(
          color: c.title,
          fontWeight: FontWeight.w600,
        ),
      ),
      row('ส่วนลด (บริษัทออกให้)', '−${formatBaht(r.discount!)}'),
      if (r.paidInCash && r.cashCollected != null)
        row('เก็บเงินสดจากลูกค้า', formatBaht(r.cashCollected!))
      else if (!r.paidInCash && r.customerPaid != null)
        row('ลูกค้าจ่ายผ่าน QR', formatBaht(r.customerPaid!)),
      if (wallet != null)
        wallet >= 0
            ? row('บริษัทโอนเข้ากระเป๋า', formatBaht(wallet))
            : row('หักจากกระเป๋า', '−${formatBaht(wallet)}', color: c.debit),
    ];
  }

  Widget _statusChip(JobReceiptInfo r, _CardColors c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: c.cancelled.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        r.statusLabel,
        style: AppTypography.caption5.copyWith(color: c.cancelled),
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
