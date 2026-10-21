import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:massdrive/common/widgets/appbar/base_appbar.dart';
import 'package:massdrive/common/widgets/indicator/mass_loading_m.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/navigation/app_navigator.dart';
import 'package:massdrive/core/theme/app_palette.dart';
import 'package:massdrive/features/quests/domain/entities/driver_quest.dart';
import 'package:massdrive/features/quests/presentation/controllers/quests_provider.dart';
import 'package:massdrive/features/quests/presentation/screens/quest_detail_screen.dart';
import 'package:massdrive/features/quests/presentation/widgets/quest_progress_bar.dart';

/// Quest list (Grab-style, design 2): pill tabs วันนี้ / กำลังจะมาถึง /
/// ที่ผ่านมา, one card per quest with its milestone bar. Every figure comes
/// from GET /api/driver/quests?tab= — formatted here, never computed.
class QuestsScreen extends ConsumerStatefulWidget {
  const QuestsScreen({super.key});

  @override
  ConsumerState<QuestsScreen> createState() => _QuestsScreenState();
}

class _QuestsScreenState extends ConsumerState<QuestsScreen> {
  QuestTab _tab = QuestTab.today;

  Future<void> _refresh() async {
    ref.invalidate(questsTabProvider(_tab));
    try {
      await ref.read(questsTabProvider(_tab).future);
    } catch (_) {}
  }

  Future<void> _open(DriverQuest q) async {
    await AppNavigator.push(context, QuestDetailScreen(questId: q.id));
    // Back from the detail: progress or a claim may have moved.
    if (mounted) ref.invalidate(questsTabProvider(_tab));
  }

  @override
  Widget build(BuildContext context) {
    final quests = ref.watch(questsTabProvider(_tab));
    return Scaffold(
      backgroundColor: context.palette.bg,
      appBar: CommonAppBar(titleText: 'ภารกิจ & รางวัล', showLeftIcon: true),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                for (final t in QuestTab.values) ...[
                  Expanded(child: _pill(t)),
                  if (t != QuestTab.values.last) const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: quests.when(
                loading: () => const Center(child: MassLoadingM(size: 48)),
                error: (_, _) =>
                    _empty(context, 'โหลดภารกิจไม่สำเร็จ ลองดึงเพื่อรีเฟรช'),
                data: (list) => list.isEmpty
                    ? _empty(context, _tab.empty)
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: list.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (_, i) => QuestCard(
                          quest: list[i],
                          showEnds: _tab == QuestTab.today,
                          onTap: () => _open(list[i]),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(QuestTab t) {
    final on = t == _tab;
    return Material(
      color: on ? AppColors.foundationMint600 : questSurface(context),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: on ? null : () => setState(() => _tab = t),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Center(
            child: Text(
              t.label,
              style: AppTypography.caption4.copyWith(
                color: on ? Colors.white : context.palette.textSecondary,
                fontWeight: on ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _empty(BuildContext context, String message) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    children: [
      const SizedBox(height: 96),
      Icon(
        Icons.emoji_events_outlined,
        size: 52,
        color: context.palette.textTertiary,
      ),
      const SizedBox(height: 12),
      Text(
        message,
        textAlign: TextAlign.center,
        style: AppTypography.caption3.copyWith(
          color: context.palette.textSecondary,
        ),
      ),
    ],
  );
}

/// One quest on the list: dates · time window, "สิ้นสุดใน N วัน", title, area,
/// "ทำรอบขับสำเร็จ X รอบ", the milestone bar and "อีก N รอบ รับ ฿B".
class QuestCard extends StatelessWidget {
  const QuestCard({
    super.key,
    required this.quest,
    this.showEnds = true,
    this.onTap,
  });

  final DriverQuest quest;

  /// The ends-in badge belongs to the วันนี้ tab only.
  final bool showEnds;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final ends = showEnds ? quest.endsLabel : null;
    final next = quest.nextLabel;
    return Material(
      color: questSurface(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: p.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      [
                        quest.dateRange,
                        quest.timeLabel,
                      ].where((s) => s.isNotEmpty).join(' · '),
                      style: AppTypography.caption5.copyWith(
                        color: p.textSecondary,
                      ),
                    ),
                  ),
                  if (ends != null)
                    QuestEndsBadge(label: ends, sub: quest.questEndsLabel),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                quest.title,
                style: AppTypography.label2.copyWith(
                  color: p.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (quest.description != null)
                Text(
                  quest.description!,
                  style: AppTypography.caption5.copyWith(color: p.textPrimary),
                ),
              Text(
                quest.areaName,
                style: AppTypography.caption5.copyWith(color: p.textSecondary),
              ),
              const SizedBox(height: 8),
              QuestCountLine(quest: quest),
              const SizedBox(height: 6),
              QuestProgressBar(
                quest: quest,
                color: AppColors.foundationMint600,
              ),
              if (next != null) ...[
                const SizedBox(height: 2),
                Text(
                  next,
                  style: AppTypography.caption5.copyWith(
                    color: AppColors.foundationMint600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// "ทำรอบขับสำเร็จ **14** รอบ" (รอบส่งอาหาร / งาน by quest type).
class QuestCountLine extends StatelessWidget {
  const QuestCountLine({super.key, required this.quest});

  final DriverQuest quest;

  @override
  Widget build(BuildContext context) {
    final style = AppTypography.caption4.copyWith(
      color: context.palette.textPrimary,
    );
    return Text.rich(
      TextSpan(
        text: '${quest.countPrefix} ',
        children: [
          TextSpan(
            text: '${quest.currentCount}',
            style: style.copyWith(fontWeight: FontWeight.w700),
          ),
          TextSpan(text: ' ${quest.countSuffix}'),
        ],
      ),
      style: style,
    );
  }
}

/// Orange "สิ้นสุดใน 4 วัน" / "สิ้นสุดวันนี้" pill.
class QuestEndsBadge extends StatelessWidget {
  const QuestEndsBadge({super.key, required this.label, this.sub});

  final String label;

  /// "ภารกิจถึง 30 พ.ย." under a round badge.
  final String? sub;

  @override
  Widget build(BuildContext context) {
    final badge = _badge();
    if (sub == null) return badge;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        badge,
        const SizedBox(height: 2),
        Text(
          sub!,
          style: AppTypography.caption5.copyWith(
            color: context.palette.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _badge() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: AppColors.foundationOrange500.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      label,
      style: AppTypography.caption5.copyWith(
        color: AppColors.foundationOrange500,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
