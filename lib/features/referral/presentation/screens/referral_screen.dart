import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:massdrive/common/widgets/appbar/base_appbar.dart';
import 'package:massdrive/common/widgets/indicator/mass_loading_m.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/theme/app_palette.dart';
import 'package:massdrive/core/utils/baht.dart';
import 'package:massdrive/features/referral/domain/driver_referral.dart';
import 'package:massdrive/features/referral/presentation/referral_providers.dart';
import 'package:massdrive/features/referral/presentation/widgets/referral_code_field.dart';
import 'package:share_plus/share_plus.dart';

const _green = AppColors.semanticSupportMintBgHigh;

/// "ชวนเพื่อนมาขับ": this driver's code to share, the rule, the drivers they
/// referred with each one's progress, and — while the backend offers it —
/// the field to enter the code of whoever referred them.
class ReferralScreen extends ConsumerWidget {
  const ReferralScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(driverReferralProvider);
    Future<void> refresh() => ref.refresh(driverReferralProvider.future);

    return Scaffold(
      backgroundColor: context.palette.bg,
      appBar: CommonAppBar(titleText: 'ชวนเพื่อนมาขับ', showLeftIcon: true),
      body: RefreshIndicator(
        onRefresh: refresh,
        child: async.when(
          loading: () => const Center(child: MassLoadingM(size: 64)),
          error: (_, _) => _Message(
            icon: Icons.wifi_off_rounded,
            title: 'โหลดข้อมูลไม่สำเร็จ',
            body: 'ดึงหน้าจอลงเพื่อลองใหม่',
          ),
          data: (info) => info.enabled
              ? _Body(info: info)
              : const _Message(
                  icon: Icons.group_add_outlined,
                  title: 'ยังไม่เปิดให้ชวนเพื่อนตอนนี้',
                  body: 'โปรดติดตามประกาศจากบริษัท',
                ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.info});

  final ReferralInfo info;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        24 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      children: [
        _InviteCard(info: info),
        const SizedBox(height: 12),
        _SummaryRow(summary: info.summary),
        const ReferralCodeCard(padding: EdgeInsets.only(top: 12)),
        const SizedBox(height: 20),
        Text(
          'เพื่อนที่คุณชวน',
          style: AppTypography.heading6.copyWith(color: p.textPrimary),
        ),
        const SizedBox(height: 8),
        if (info.referrals.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'ยังไม่มีเพื่อนที่สมัครด้วยโค้ดของคุณ\nแชร์โค้ดให้เพื่อนเลย',
              textAlign: TextAlign.center,
              style: AppTypography.caption4.copyWith(color: p.textSecondary),
            ),
          )
        else
          for (final r in info.referrals) ...[
            _ReferralTile(referral: r),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}

/// The code, the rule and the share / copy actions.
class _InviteCard extends StatelessWidget {
  const _InviteCard({required this.info});

  final ReferralInfo info;

  Future<void> _copy(BuildContext context, String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!context.mounted) return;
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('คัดลอกโค้ด $code แล้ว')));
  }

  Future<void> _share(BuildContext context, String code) async {
    final box = context.findRenderObject() as RenderBox?;
    final text = info.shareMessage.isNotEmpty
        ? info.shareMessage
        : 'สมัครขับกับ Mass ใส่โค้ด $code ตอนสมัคร';
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        // iPad needs an anchor for the share popover.
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final code = info.code;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D995C), Color(0xFF0B7A4B)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.group_add_rounded, color: Colors.white, size: 32),
          const SizedBox(height: 8),
          Text(
            info.ruleText,
            style: AppTypography.heading5.copyWith(color: Colors.white),
          ),
          if (info.refereeBonusBaht > 0) ...[
            const SizedBox(height: 4),
            Text(
              'เพื่อนก็ได้รับ ${formatBaht(info.refereeBonusBaht)} ด้วย',
              style: AppTypography.caption4.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (code != null) ...[
            Text(
              'โค้ดของคุณ',
              style: AppTypography.caption5.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 4),
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _copy(context, code),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          code,
                          style: AppTypography.heading4.copyWith(
                            color: _green,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      const Icon(Icons.copy_rounded, color: _green, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        'คัดลอก',
                        style: AppTypography.caption4.copyWith(color: _green),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Builder(
              builder: (btnContext) => OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _share(btnContext, code),
                icon: const Icon(Icons.ios_share_rounded),
                label: const Text('แชร์โค้ดให้เพื่อน'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.summary});

  final ReferralSummary summary;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    Widget cell(String value, String label) => Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: AppTypography.heading5.copyWith(color: p.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTypography.caption5.copyWith(color: p.textSecondary),
          ),
        ],
      ),
    );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
      ),
      child: Row(
        children: [
          cell('${summary.invited}', 'ชวนแล้ว'),
          cell('${summary.pending}', 'กำลังวิ่ง'),
          cell('${summary.completed}', 'สำเร็จ'),
          cell(formatBaht(summary.earnedBaht), 'ได้รับแล้ว'),
        ],
      ),
    );
  }
}

/// One referred driver: name, status, `completed_jobs / required_jobs` and
/// the deadline ("รออนุมัติ" until they are approved). Uses the referral's
/// own frozen rules.
class _ReferralTile extends StatelessWidget {
  const _ReferralTile({required this.referral});

  final ReferralProgress referral;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = referral;
    final date = DateFormat('d MMM yyyy', 'th_TH');
    final (chipBg, chipFg, chipText) = switch (r.status) {
      ReferralStatus.completed => (
        AppColors.foundationGreen100,
        AppColors.foundationGreen600,
        r.status.label,
      ),
      ReferralStatus.expired || ReferralStatus.cancelled => (
        AppColors.foundationRed100,
        AppColors.foundationRed800,
        r.status.label,
      ),
      ReferralStatus.pending when r.waitingApproval => (
        AppColors.foundationOrange100,
        AppColors.foundationOrange600,
        'รออนุมัติ',
      ),
      ReferralStatus.pending => (
        AppColors.foundationOrange100,
        AppColors.foundationOrange600,
        r.status.label,
      ),
    };
    final String? footer = switch (r.status) {
      ReferralStatus.completed =>
        r.paidAt == null
            ? 'ได้รับ ${formatBaht(r.bonusBaht)} แล้ว'
            : 'ได้รับ ${formatBaht(r.bonusBaht)} เมื่อ ${date.format(r.paidAt!)}',
      ReferralStatus.pending when r.waitingApproval =>
        'รอเพื่อนผ่านการอนุมัติ แล้วจึงเริ่มนับ ${r.requiredJobs} งาน',
      ReferralStatus.pending =>
        r.deadlineAt == null
            ? null
            : 'ต้องครบภายใน ${date.format(r.deadlineAt!)}',
      _ => null,
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  r.name.isEmpty ? 'เพื่อนที่คุณชวน' : r.name,
                  style: AppTypography.caption3.copyWith(
                    color: p.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: chipBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  chipText,
                  style: AppTypography.caption5.copyWith(
                    color: chipFg,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: r.progress,
              minHeight: 8,
              backgroundColor: p.surfaceAlt,
              color:
                  r.status == ReferralStatus.expired ||
                      r.status == ReferralStatus.cancelled
                  ? p.textTertiary
                  : _green,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  'วิ่งแล้ว ${r.completedJobs}/${r.requiredJobs} งาน',
                  style: AppTypography.caption5.copyWith(
                    color: p.textSecondary,
                  ),
                ),
              ),
              Text(
                'โบนัส ${formatBaht(r.bonusBaht)}',
                style: AppTypography.caption5.copyWith(color: p.textSecondary),
              ),
            ],
          ),
          if (footer != null) ...[
            const SizedBox(height: 4),
            Text(
              footer,
              style: AppTypography.caption5.copyWith(color: p.textTertiary),
            ),
          ],
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.22),
        Icon(icon, size: 56, color: p.textTertiary),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppTypography.heading5.copyWith(color: p.textPrimary),
        ),
        const SizedBox(height: 6),
        Text(
          body,
          textAlign: TextAlign.center,
          style: AppTypography.caption4.copyWith(color: p.textSecondary),
        ),
      ],
    );
  }
}
