import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:massdrive/common/widgets/appbar/base_appbar.dart';
import 'package:massdrive/features/profile/presentation/controllers/today_trips_provider.dart';
import 'package:massdrive/features/profile/presentation/screens/trip_calendar_screen.dart';
import 'package:massdrive/features/wallet/domain/entities/transaction.dart';
import 'package:massdrive/common/widgets/indicator/wave_dot_indicator.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/navigation/app_navigator.dart';
import 'package:massdrive/features/edit_profile/presentation/screens/edit_profile_screen.dart';
import 'package:massdrive/features/profile/domain/entities/driver_profile_entity.dart';
import 'package:massdrive/features/profile/presentation/controllers/profile_controller.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with TickerProviderStateMixin {
  late bool isNavigateToConsent = false;

  @override
  void initState() {
    super.initState();
    // The profile controller is keepAlive (last fetched on home load), so
    // re-opening this screen shows stale counts. Refetch on open so งานสำเร็จ /
    // เปอร์เซ็นต์รับ-ยกเลิก reflect the latest after finishing/declining a job.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(profileControllerProvider.notifier).fetchProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileControllerProvider);
    final profile = profileState.profile;

    return Scaffold(
      appBar: CommonAppBar(titleText: 'โปรไฟล์', showLeftIcon: true),
      body: Container(
        color: AppColors.semanticGrayNeutralFgHigh,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(todayTripsProvider);
                  await ref
                      .read(profileControllerProvider.notifier)
                      .fetchProfile();
                },
                child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),

                        if (profileState.isLoading)
                          Center(child: _buildLoading())
                        else if (profile != null) ...[
                          _ProfileHeader(
                            profile: profile,
                            onTap: () {
                              AppNavigator.push(
                                context,
                                const EditProfileScreen(),
                              );
                            },
                          ),

                          const SizedBox(height: 20),

                          _WeeklyOverviewCard(profile: profile),

                          const SizedBox(height: 20),

                          const _TodayTripsSection(),

                          const SizedBox(height: 32),
                        ],

                        // "บัญชีของฉัน" quick-actions section hidden for now — the
                        // tiles (กล่องข้อความ / ตารางรายได้ / เช่ารถ / …) aren't wired
                        // to anything yet.
                      ],
                    ),
                  ),
                ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return SizedBox(
      width: 100,
      child: Container(
        color: AppColors.semanticGrayNeutralBgLightgray,
        child: const Center(child: BaseWaveDotsIndicator()),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final VoidCallback onTap;
  final DriverProfileEntity profile;

  const _ProfileHeader({required this.onTap, required this.profile});

  @override
  Widget build(BuildContext context) {
    String? profilePhotoUrl;
    for (final doc in profile.documents) {
      if (doc.type == 'profile_photo' || doc.type == 'profilePhoto') {
        profilePhotoUrl = doc.mediaUrl;
        break;
      }
    }
    final hasImage = profilePhotoUrl != null && profilePhotoUrl.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.grey[800],
                backgroundImage: hasImage ? NetworkImage(profilePhotoUrl) : null,
                child: !hasImage
                    ? const Icon(
                        Icons.person,
                        color: Colors.white70,
                        size: 28,
                      )
                    : null,
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.fullName,
                      style: AppTypography.caption3.copyWith(
                        color: AppColors.semanticGrayNeutralBgWhite,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          color: AppColors.semanticWarningBorderHigh,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          profile.rating.toStringAsFixed(1),
                          style: AppTypography.caption4.copyWith(
                            color: AppColors.semanticGrayNeutralBgWhite,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Icon(Icons.chevron_right, color: Colors.white54),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeeklyOverviewCard extends StatelessWidget {
  final DriverProfileEntity profile;

  const _WeeklyOverviewCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () =>
            AppNavigator.push(context, const TripCalendarScreen()),
        child: Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [
            AppColors.semanticGrayNeutralFgMidOnGray,
            AppColors.semanticGrayNeutralFgMidOnGray,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "ภาพรวมรายสัปดาห์",
                style: AppTypography.caption4.copyWith(
                  color: AppColors.semanticGrayNeutralBgWhite,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right,
                color: AppColors.semanticGrayNeutralBgWhite,
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
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
        ],
      ),
        ),
      ),
    );
  }
}

/// Today's completed trips (from GET /api/driver/earnings/transactions filtered
/// to today + FARE_PAYMENT) — a count header + a compact list.
class _TodayTripsSection extends ConsumerWidget {
  const _TodayTripsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(todayTripsProvider);
    final count = tripsAsync.asData?.value.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.semanticGrayNeutralFgMidOnGray,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "งานที่ทำวันนี้",
                style: AppTypography.caption3.copyWith(
                  color: AppColors.semanticGrayNeutralBgWhite,
                ),
              ),
              const Spacer(),
              if (count != null)
                Text(
                  "$count รายการ",
                  style: AppTypography.caption4.copyWith(
                    color: AppColors.foundationOrange500,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 8),
          tripsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            error: (_, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                "โหลดรายการงานไม่สำเร็จ",
                style: AppTypography.caption4.copyWith(color: Colors.white54),
              ),
            ),
            data: (trips) => trips.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      "ยังไม่มีงานในวันนี้",
                      style: AppTypography.caption4.copyWith(
                        color: Colors.white54,
                      ),
                    ),
                  )
                : Column(
                    children: trips
                        .map((t) => _TodayTripTile(trip: t))
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _TodayTripTile extends StatelessWidget {
  final Transaction trip;

  const _TodayTripTile({required this.trip});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.semanticSuccessBgHigh.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.directions_car_rounded,
              color: AppColors.semanticSuccessBgHigh,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "ค่าโดยสาร",
                  style: AppTypography.caption4.copyWith(
                    color: AppColors.semanticGrayNeutralBgWhite,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('HH:mm').format(trip.createdAt.toLocal()),
                  style: AppTypography.caption5.copyWith(color: Colors.white54),
                ),
              ],
            ),
          ),
          Text(
            "+฿${trip.absoluteAmount.toStringAsFixed(0)}",
            style: AppTypography.caption3.copyWith(
              color: AppColors.semanticSupportMintBgHigh,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
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
          style: AppTypography.caption3.copyWith(
            color: AppColors.semanticGrayNeutralBgWhite,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTypography.caption4.copyWith(
            color: AppColors.semanticGrayNeutralBgWhite,
          ),
        ),
      ],
    );
  }
}

