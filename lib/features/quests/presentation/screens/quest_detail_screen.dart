import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:massdrive/common/widgets/appbar/base_appbar.dart';
import 'package:massdrive/common/widgets/indicator/mass_loading_m.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/theme/app_palette.dart';
import 'package:massdrive/core/utils/baht.dart';
import 'package:massdrive/features/dependency_injection.dart';
import 'package:massdrive/features/home/data/sources/quest_api_service.dart';
import 'package:massdrive/features/quests/domain/entities/driver_quest.dart';
import 'package:massdrive/features/quests/presentation/controllers/quests_provider.dart';
import 'package:massdrive/features/quests/presentation/screens/quests_screen.dart';
import 'package:massdrive/features/quests/presentation/widgets/quest_progress_bar.dart';

/// One quest (Grab-style detail): dates + title, the progress card with each
/// step's cumulative reward, the running count, the payout breakdown of the
/// reached steps, and the terms. From GET /api/driver/quests/{id}.
class QuestDetailScreen extends ConsumerStatefulWidget {
  const QuestDetailScreen({super.key, required this.questId});

  final String questId;

  @override
  ConsumerState<QuestDetailScreen> createState() => _QuestDetailScreenState();
}

class _QuestDetailScreenState extends ConsumerState<QuestDetailScreen> {
  bool _claiming = false;

  Future<void> _claim() async {
    setState(() => _claiming = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await getIt<QuestApiService>().claimQuest(widget.questId);
      messenger.showSnackBar(
        const SnackBar(content: Text('รับรางวัลแล้ว รอผู้ดูแลระบบตรวจสอบ')),
      );
      ref.invalidate(questDetailProvider(widget.questId));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('รับรางวัลไม่สำเร็จ ลองใหม่อีกครั้ง')),
      );
    } finally {
      if (mounted) setState(() => _claiming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(questDetailProvider(widget.questId));
    // Deleted / gone (404): say so and go back to the list.
    ref.listen(questDetailProvider(widget.questId), (_, next) {
      if (next.error is QuestGoneException && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('ภารกิจนี้ไม่มีแล้ว')));
        Navigator.of(context).maybePop();
      }
    });
    return Scaffold(
      backgroundColor: context.palette.bg,
      appBar: CommonAppBar(titleText: '', showLeftIcon: true),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(questDetailProvider(widget.questId));
          try {
            await ref.read(questDetailProvider(widget.questId).future);
          } catch (_) {}
        },
        child: async.when(
          loading: () => const Center(child: MassLoadingM(size: 48)),
          error: (e, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const SizedBox(height: 96),
              Text(
                e is QuestGoneException
                    ? 'ภารกิจนี้ไม่มีแล้ว'
                    : 'โหลดภารกิจไม่สำเร็จ ลองดึงเพื่อรีเฟรช',
                textAlign: TextAlign.center,
                style: AppTypography.caption3.copyWith(
                  color: context.palette.textSecondary,
                ),
              ),
            ],
          ),
          data: (q) =>
              QuestDetailBody(quest: q, claiming: _claiming, onClaim: _claim),
        ),
      ),
    );
  }
}

/// The detail content, split out so it renders from a [DriverQuest] alone.
class QuestDetailBody extends StatelessWidget {
  const QuestDetailBody({
    super.key,
    required this.quest,
    this.claiming = false,
    this.onClaim,
  });

  final DriverQuest quest;
  final bool claiming;
  final VoidCallback? onClaim;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final q = quest;
    final ends = q.endsLabel;
    final reached = q.reachedSteps;
    final terms = q.terms;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                q.dateRange,
                style: AppTypography.caption4.copyWith(color: p.textSecondary),
              ),
            ),
            // Only while it is still running (not for an ended quest).
            if (ends != null && q.status != 'ENDED' && q.status != 'CLAIMED')
              QuestEndsBadge(label: ends),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          q.title,
          style: AppTypography.heading5.copyWith(color: p.textPrimary),
        ),
        if (q.description != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              q.description!,
              style: AppTypography.caption4.copyWith(color: p.textSecondary),
            ),
          ),
        const SizedBox(height: 16),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              QuestCountLine(count: q.currentCount),
              const SizedBox(height: 8),
              QuestProgressBar(quest: q, color: AppColors.foundationMint600),
              for (final m in q.milestones) _stepRow(context, m),
            ],
          ),
        ),
        _Card(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'สถิติที่กำลังดำเนินการ',
                  style: AppTypography.caption3.copyWith(color: p.textPrimary),
                ),
              ),
              Text(
                '${q.currentCount} รอบ',
                style: AppTypography.caption3.copyWith(
                  color: p.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'แจกแจงรายละเอียดการชำระเงิน',
                style: AppTypography.caption3.copyWith(
                  color: p.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              if (reached.isEmpty)
                Text(
                  'ยังไม่มีรายการ',
                  style: AppTypography.caption4.copyWith(
                    color: p.textSecondary,
                  ),
                )
              else
                for (final m in reached)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'ขั้น ${m.trips} รอบ · ${formatBaht(m.bonus)}',
                            style: AppTypography.caption4.copyWith(
                              color: p.textPrimary,
                            ),
                          ),
                        ),
                        if (m.payoutStatus != null)
                          QuestPayoutChip(status: m.payoutStatus!),
                      ],
                    ),
                  ),
            ],
          ),
        ),
        if (terms != null) _TermsCard(terms: terms),
        if (q.claimable) ...[
          const SizedBox(height: 8),
          FilledButton(
            onPressed: claiming ? null : onClaim,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.foundationMint600,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: claiming
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'รับรางวัล',
                    style: AppTypography.label2.copyWith(color: Colors.white),
                  ),
          ),
        ],
      ],
    );
  }

  /// "✓ รอบขับ 10 รอบ ........ ฿100" (cumulative reward at that step).
  Widget _stepRow(BuildContext context, QuestMilestoneStep m) {
    final p = context.palette;
    final color = m.reached ? AppColors.foundationMint600 : p.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: p.border)),
      ),
      child: Row(
        children: [
          if (m.reached) ...[
            const Icon(
              Icons.check_rounded,
              size: 16,
              color: AppColors.foundationMint600,
            ),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Text(
              'รอบขับ ${m.trips} รอบ',
              style: AppTypography.caption4.copyWith(color: color),
            ),
          ),
          Text(
            formatBaht(m.cumulative),
            style: AppTypography.caption3.copyWith(
              color: m.reached ? AppColors.foundationMint600 : p.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Payout state of a reached step: รอตรวจสอบ (grey), จ่ายแล้ว (green),
/// ไม่อนุมัติ (red).
class QuestPayoutChip extends StatelessWidget {
  const QuestPayoutChip({super.key, required this.status});

  final QuestPayoutStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      QuestPayoutStatus.pending => context.palette.textSecondary,
      QuestPayoutStatus.paid => AppColors.foundationMint600,
      QuestPayoutStatus.rejected => AppColors.semanticErrorFgHigh,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status.label,
        style: AppTypography.caption5.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: questSurface(context),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: context.palette.border),
    ),
    child: child,
  );
}

/// "ข้อกำหนดและเงื่อนไข" — collapsed until tapped.
class _TermsCard extends StatefulWidget {
  const _TermsCard({required this.terms});

  final String terms;

  @override
  State<_TermsCard> createState() => _TermsCardState();
}

class _TermsCardState extends State<_TermsCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return _Card(
      child: InkWell(
        onTap: () => setState(() => _open = !_open),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'ข้อกำหนดและเงื่อนไข',
                    style: AppTypography.caption3.copyWith(
                      color: p.textPrimary,
                    ),
                  ),
                ),
                Icon(
                  _open
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: p.textSecondary,
                ),
              ],
            ),
            if (_open)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  widget.terms,
                  style: AppTypography.caption4.copyWith(
                    color: p.textSecondary,
                    height: 1.5,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
