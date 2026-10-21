import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:massdrive/common/widgets/appbar/base_appbar.dart';
import 'package:massdrive/common/widgets/indicator/mass_loading_m.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/theme/app_palette.dart';
import 'package:massdrive/features/income/presentation/controllers/wallet_controller.dart';
import 'package:massdrive/features/profile/domain/entities/driver_profile_entity.dart';
import 'package:massdrive/features/profile/presentation/controllers/profile_controller.dart';
import 'package:massdrive/features/quests/domain/entities/driver_quest.dart';
import 'package:massdrive/features/quests/presentation/controllers/quests_provider.dart';
import 'package:massdrive/features/quests/presentation/widgets/quest_progress_bar.dart';
import 'package:massdrive/core/utils/baht.dart';
import 'package:go_router/go_router.dart';
import 'package:massdrive/core/constants/app_routes.dart';

/// Driver profile (design 5): centred photo, name, rating and tier; this
/// week's income and completed jobs; the weekly rates; and the quest being
/// worked on with its reward ladder. Every figure comes from the backend.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // The profile and wallet controllers are keepAlive (last fetched on
    // home load), so re-opening this screen would show stale counts. Refetch
    // on open so the week's income / jobs / rates are current.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(profileControllerProvider.notifier).fetchProfile();
      ref.read(walletControllerProvider.notifier).fetchAll(silent: true);
    });
  }

  Future<void> _refresh() async {
    ref.invalidate(questsTabProvider(QuestTab.today));
    ref.invalidate(tierProvider);
    await Future.wait([
      ref.read(profileControllerProvider.notifier).fetchProfile(),
      ref.read(walletControllerProvider.notifier).fetchAll(silent: true),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileControllerProvider);
    final profile = profileState.profile;
    return Scaffold(
      backgroundColor: context.palette.bg,
      appBar: CommonAppBar(titleText: 'โปรไฟล์', showLeftIcon: true),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              if (profile == null && profileState.isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: MassLoadingM(size: 64)),
                )
              else if (profile != null) ...[
                _ProfileHeader(
                  profile: profile,
                  onTap: () => context.push(AppRoutes.editProfileNamedPage),
                ),
                const SizedBox(height: 16),
                _WeekCards(profile: profile),
                const SizedBox(height: 12),
                _WeeklyRates(profile: profile),
                const SizedBox(height: 12),
                const _CurrentQuestCard(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Centred photo, name, then "⭐ 5.0 · BRONZE". Tap → edit profile.
class _ProfileHeader extends ConsumerWidget {
  const _ProfileHeader({required this.onTap, required this.profile});

  final VoidCallback onTap;
  final DriverProfileEntity profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String? photo;
    for (final doc in profile.documents) {
      if (doc.type == 'profile_photo' || doc.type == 'profilePhoto') {
        photo = doc.mediaUrl;
        break;
      }
    }
    final hasImage = photo != null && photo.isNotEmpty;
    final tier =
        ref.watch(tierProvider).asData?.value?.currentTier ??
        profile.incentiveTier;
    final p = context.palette;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            CircleAvatar(
              radius: 38,
              backgroundColor: p.surface,
              backgroundImage: hasImage ? NetworkImage(photo) : null,
              child: !hasImage
                  ? Icon(Icons.person, color: p.textSecondary, size: 38)
                  : null,
            ),
            const SizedBox(height: 10),
            Text(
              profile.fullName,
              textAlign: TextAlign.center,
              style: AppTypography.heading5.copyWith(color: p.textPrimary),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.star_rounded,
                  color: AppColors.semanticWarningBorderHigh,
                  size: 18,
                ),
                const SizedBox(width: 2),
                Text(
                  profile.rating.toStringAsFixed(1),
                  style: AppTypography.caption4.copyWith(
                    color: p.textSecondary,
                  ),
                ),
                if (tier != null && tier.trim().isNotEmpty) ...[
                  Text(
                    '  ·  ',
                    style: AppTypography.caption4.copyWith(
                      color: p.textSecondary,
                    ),
                  ),
                  Icon(
                    Icons.military_tech_rounded,
                    size: 18,
                    color: _tierColor(tier),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    tier.toUpperCase(),
                    style: AppTypography.caption4.copyWith(
                      color: p.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Color _tierColor(String tier) => switch (tier.toUpperCase()) {
  'GOLD' => const Color(0xFFE6B422),
  'SILVER' => const Color(0xFFB8C0CC),
  _ => const Color(0xFFCD7F32),
};

/// Two green cards: this week's income (wallet overview, BE) and the
/// week's completed jobs. Tap → the income schedule.
class _WeekCards extends ConsumerWidget {
  const _WeekCards({required this.profile});

  final DriverProfileEntity profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final week = ref.watch(
      walletControllerProvider.select((s) => s.earningsWeek),
    );
    Widget card(String label, String value) => Expanded(
      child: Material(
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push(AppRoutes.tripCalendarNamedPage),
          child: Ink(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0D995C), Color(0xFF0B7A4B)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.caption5.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTypography.heading4.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return Row(
      children: [
        card('รายได้สัปดาห์นี้', formatBaht(week)),
        const SizedBox(width: 10),
        card('งานสำเร็จ', '${profile.weeklyCompletedJobs}'),
      ],
    );
  }
}

/// "ภาพรวมรายสัปดาห์": งานสำเร็จ / เปอร์เซ็นต์รับ / เปอร์เซ็นต์ยกเลิก.
class _WeeklyRates extends StatelessWidget {
  const _WeeklyRates({required this.profile});

  final DriverProfileEntity profile;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: questSurface(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.palette.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push(AppRoutes.tripCalendarNamedPage),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // acceptance_rate / cancellation_rate are merged in from
              // GET /api/driver/tier by ProfileController (the profile endpoint
              // doesn't carry them). งานสำเร็จ = weekly_completed_jobs.
              _StatItem(
                value: "${profile.weeklyCompletedJobs}",
                label: "งานสำเร็จ",
              ),
              _StatItem(
                value: "${profile.acceptanceRate.toStringAsFixed(0)}%",
                label: "เปอร์เซ็นต์รับ",
              ),
              _StatItem(
                value: "${profile.cancellationRate.toStringAsFixed(0)}%",
                label: "เปอร์เซ็นต์ยกเลิก",
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The quest being worked on (first of today's tab): "รับสูงสุด ฿500", the
/// orange ladder with each step's cumulative reward, and what is done so
/// far. Without one it is a plain entry to ภารกิจ & รางวัล.
class _CurrentQuestCard extends ConsumerWidget {
  const _CurrentQuestCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quests =
        ref.watch(questsTabProvider(QuestTab.today)).asData?.value ?? const [];
    final q = quests.isEmpty
        ? null
        : quests.firstWhere(
            (x) => x.status == 'IN_PROGRESS',
            orElse: () => quests.first,
          );
    final p = context.palette;
    const orange = AppColors.foundationOrange500;
    return Material(
      color: questSurface(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: q == null ? p.border : orange.withValues(alpha: 0.4),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push(AppRoutes.questsNamedPage),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.emoji_events_rounded,
                    color: orange,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      q == null ? 'ภารกิจ & รางวัล' : 'ภารกิจที่กำลังทำ',
                      style: AppTypography.caption3.copyWith(
                        color: p.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (q != null && q.maxReward > 0)
                    Text(
                      'รับสูงสุด ${formatBaht(q.maxReward)}',
                      style: AppTypography.caption4.copyWith(
                        color: orange,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  else
                    Icon(Icons.chevron_right, color: p.textSecondary),
                ],
              ),
              if (q == null) ...[
                const SizedBox(height: 4),
                Text(
                  'ยังไม่มีภารกิจตอนนี้ · ดูภารกิจทั้งหมด',
                  style: AppTypography.caption5.copyWith(
                    color: p.textSecondary,
                  ),
                ),
              ] else ...[
                const SizedBox(height: 4),
                Text(
                  q.title,
                  style: AppTypography.caption5.copyWith(
                    color: p.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                QuestProgressBar(
                  quest: q,
                  color: orange,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE75615), Color(0xFFEF7F4D)],
                  ),
                  labels: QuestBarLabel.cumulative,
                ),
                Text(
                  'ทำแล้ว ${q.currentCount}/${q.targetCount} รอบ'
                  ' · ได้แล้ว ${formatBaht(q.earnedAmount)}',
                  style: AppTypography.caption5.copyWith(
                    color: p.textSecondary,
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

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.heading5.copyWith(
            color: context.palette.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.caption5.copyWith(
            color: context.palette.textSecondary,
          ),
        ),
      ],
    );
  }
}
