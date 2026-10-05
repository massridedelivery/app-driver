import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:massdrive/common/widgets/appbar/base_appbar.dart';
import 'package:massdrive/common/widgets/indicator/mass_loading_m.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/theme/app_palette.dart';
import 'package:massdrive/features/dependency_injection.dart';
import 'package:massdrive/features/home/data/sources/quest_api_service.dart';
import 'package:massdrive/features/quests/domain/entities/quest.dart';
import 'package:massdrive/features/quests/presentation/controllers/quests_provider.dart';

/// Driver quests / incentives (BE PR #132). Lists active quests with their
/// progress, stepped milestones, and the reward-claim action.
///
/// Rewards are NOT paid instantly: a claimed milestone is queued for admin
/// approval, so every reward message says "รอตรวจสอบ/อนุมัติ" and the amount
/// lands in the wallet only once approved.
class QuestsScreen extends ConsumerWidget {
  const QuestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questsAsync = ref.watch(questsProvider);
    final tier = ref.watch(tierProvider).asData?.value;
    return Scaffold(
      backgroundColor: context.palette.bg,
      appBar: CommonAppBar(titleText: 'ภารกิจ & รางวัล', showLeftIcon: true),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(tierProvider);
          ref.invalidate(questsProvider);
          await ref.read(questsProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            if (tier != null) ...[
              _TierCard(tier: tier),
              const SizedBox(height: 20),
            ],
            Text(
              'ภารกิจ',
              style: AppTypography.heading5
                  .copyWith(color: context.palette.textPrimary),
            ),
            const SizedBox(height: 12),
            ...questsAsync.when(
              loading: () => [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: MassLoadingM(size: 48)),
                ),
              ],
              error: (_, _) =>
                  [_emptyInline(context, 'โหลดภารกิจไม่สำเร็จ ลองดึงเพื่อรีเฟรช')],
              data: (quests) => quests.isEmpty
                  ? [_emptyInline(context, 'ยังไม่มีภารกิจตอนนี้')]
                  : [
                      for (int i = 0; i < quests.length; i++) ...[
                        _QuestCard(
                          quest: quests[i],
                          onClaim: () => _claim(context, ref, quests[i]),
                        ),
                        if (i < quests.length - 1) const SizedBox(height: 12),
                      ],
                    ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _claim(BuildContext context, WidgetRef ref, Quest quest) async {
    try {
      await getIt<QuestApiService>().claimQuest(quest.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'รับรางวัลแล้ว 🎉 รางวัลกำลังรอตรวจสอบ/อนุมัติ — '
            'ยอดจะเข้ากระเป๋าหลังแอดมินอนุมัติ',
          ),
        ),
      );
      ref.invalidate(questsProvider);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('รับรางวัลไม่สำเร็จ ลองใหม่อีกครั้ง')),
      );
    }
  }

  Widget _emptyInline(BuildContext context, String message) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            Icon(Icons.emoji_events_outlined,
                size: 56, color: context.palette.textTertiary),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.caption3
                  .copyWith(color: context.palette.textSecondary),
            ),
          ],
        ),
      );
}

class _TierCard extends StatelessWidget {
  final TierInfo tier;
  const _TierCard({required this.tier});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF373535),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.workspace_premium,
                  color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Text(
                'ระดับ ${tier.currentTier}',
                style: AppTypography.heading5.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          if (tier.nextTier != null) ...[
            const SizedBox(height: 8),
            Text(
              'อีก ${tier.jobsToNextTier} งาน ถึงระดับ ${tier.nextTier}',
              style: AppTypography.caption4
                  .copyWith(color: Colors.white.withValues(alpha: 0.75)),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _benefit('โบนัสภารกิจ x${tier.questMultiplier}'),
              if (tier.baseFareBonus > 0)
                _benefit('ค่างาน +${_money.format(tier.baseFareBonus)}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _benefit(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTypography.caption5.copyWith(color: Colors.white),
        ),
      );
}

final _money = NumberFormat('#,##0');

class _QuestCard extends StatelessWidget {
  final Quest quest;
  final VoidCallback onClaim;

  const _QuestCard({required this.quest, required this.onClaim});

  @override
  Widget build(BuildContext context) {
    final maxTarget = quest.maxTarget;
    final pct = maxTarget > 0 ? (quest.progress / maxTarget).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + status.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  quest.title.isEmpty ? 'ภารกิจ' : quest.title,
                  style: AppTypography.heading5
                      .copyWith(color: context.palette.textPrimary),
                ),
              ),
              if (quest.isPendingReview) const _PendingChip(),
            ],
          ),
          if (quest.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              quest.description,
              style: AppTypography.caption4
                  .copyWith(color: context.palette.textSecondary),
            ),
          ],

          // Scope chips: service label + vehicle-type restriction.
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (quest.serviceLabel != null)
                _Chip(label: quest.serviceLabel!, icon: Icons.all_inclusive),
              if (quest.vehicleTypes.isNotEmpty)
                _Chip(
                  label: quest.vehicleTypes.join(', '),
                  icon: Icons.directions_car_filled_outlined,
                ),
            ],
          ),

          // Progress.
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: context.palette.surfaceAlt,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.foundationOrange500,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'ทำไปแล้ว ${quest.progress}${maxTarget > 0 ? ' / $maxTarget' : ''} งาน',
            style: AppTypography.caption5
                .copyWith(color: context.palette.textTertiary),
          ),

          // Milestones (stepped rewards) or single reward.
          if (quest.hasMilestones) ...[
            const SizedBox(height: 12),
            ...quest.milestones.map(
              (m) => _MilestoneRow(milestone: m, progress: quest.progress),
            ),
          ] else if (quest.bonus > 0) ...[
            const SizedBox(height: 12),
            Text(
              'รางวัล ฿${_money.format(quest.bonus)}',
              style: AppTypography.label2.copyWith(
                color: AppColors.foundationOrange600,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],

          // Claim action.
          if (quest.claimable) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: onClaim,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.foundationOrange600,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'รับรางวัล',
                  style: AppTypography.label1.copyWith(color: Colors.white),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MilestoneRow extends StatelessWidget {
  final QuestMilestone milestone;
  final int progress;

  const _MilestoneRow({required this.milestone, required this.progress});

  @override
  Widget build(BuildContext context) {
    final reached = progress >= milestone.trips;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            reached ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 18,
            color: reached
                ? AppColors.semanticSuccessBorderHigh
                : context.palette.textTertiary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${milestone.trips} งาน · ฿${_money.format(milestone.bonus)}',
              style: AppTypography.caption4.copyWith(
                color: reached
                    ? context.palette.textPrimary
                    : context.palette.textSecondary,
              ),
            ),
          ),
          // A reached milestone's reward is queued for admin approval, never
          // paid on the spot — say "รอตรวจสอบ", not "ได้รับแล้ว".
          if (reached) const _PendingChip(),
        ],
      ),
    );
  }
}

class _PendingChip extends StatelessWidget {
  const _PendingChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: context.palette.surfaceAlt,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'รอตรวจสอบ',
        style: AppTypography.caption5.copyWith(
          color: context.palette.textSecondary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _Chip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: context.palette.surfaceAlt,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: context.palette.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.caption5
                .copyWith(color: context.palette.textSecondary),
          ),
        ],
      ),
    );
  }
}
