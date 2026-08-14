import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:massdrive/common/widgets/appbar/base_appbar.dart';
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
              return SingleChildScrollView(
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

                          const SizedBox(height: 32),
                        ],

                        // "บัญชีของฉัน" quick-actions section hidden for now — the
                        // tiles (กล่องข้อความ / ตารางรายได้ / เช่ารถ / …) aren't wired
                        // to anything yet.
                      ],
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
    return Container(
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
          Text(
            "ภาพรวมรายสัปดาห์",
            style: AppTypography.caption4.copyWith(
              color: AppColors.semanticGrayNeutralBgWhite,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // acceptance_rate / cancellation_rate come straight from the
              // profile API. งานสำเร็จ (weekly_completed_jobs) is the real weekly
              // count, shown so the card is informative even before the backend
              // populates the two rates.
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

