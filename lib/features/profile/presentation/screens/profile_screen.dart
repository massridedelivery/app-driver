import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:massdrive/common/widgets/appbar/base_appbar.dart';
import 'package:massdrive/common/widgets/indicator/wave_dot_indicator.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/navigation/app_navigator.dart';
import 'package:massdrive/core/utils/app_util.dart';
import 'package:massdrive/features/edit_profile/presentation/screens/edit_profile_screen.dart';
import 'package:url_launcher/url_launcher.dart';

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

                        _ProfileHeader(
                          onTap: () {
                            AppNavigator.push(
                              context,
                              const EditProfileScreen(),
                            );
                          },
                        ),

                        const SizedBox(height: 20),

                        const _WeeklyOverviewCard(),

                        const SizedBox(height: 24),

                        Text(
                          'บัญชีของฉัน',
                          style: AppTypography.caption4.copyWith(
                            color: AppColors.semanticGrayNeutralBgWhite,
                          ),
                        ),

                        const SizedBox(height: 16),

                        const _MyAccountSection(),

                        const SizedBox(height: 32),
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

  void _inAppUpdate() {
    final appId = AppUtil.getPackageInfo().packageName;
    final url = Platform.isAndroid
        ? 'https://play.google.com/store/apps/details?id=$appId'
        : 'https://apps.apple.com/app/id$appId';
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }
}

class _ProfileHeader extends StatelessWidget {
  final VoidCallback onTap;

  const _ProfileHeader({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 28,
                backgroundImage: NetworkImage(
                  "https://i.pravatar.cc/150?img=3",
                ),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "(MB) ธนนันต์ อนุรักษ์ศิลปกุล",
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
                          "5.0",
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
  const _WeeklyOverviewCard();

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
            children: const [
              _StatItem(value: "0.0%", label: "เปอร์เซ็นต์รับ"),
              _StatItem(value: "0.0%", label: "เปอร์เซ็นต์ยกเลิก"),
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

class _MyAccountSection extends StatelessWidget {
  const _MyAccountSection();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: const [
        _AccountMenuItem(
          icon: Icons.chat_bubble_outline,
          label: "กล่องข้อความ",
          showDot: true,
        ),
        _AccountMenuItem(
          icon: Icons.receipt_long_outlined,
          label: "ตารางรายได้",
        ),
        _AccountMenuItem(icon: Icons.directions_car_outlined, label: "เช่ารถ"),
        _AccountMenuItem(
          icon: Icons.lightbulb_outline,
          label: "สิ่งที่น่าสนใจ",
        ),
        _AccountMenuItem(icon: Icons.more_horiz, label: "เพิ่มเติม"),
      ],
    );
  }
}

class _AccountMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool showDot;

  const _AccountMenuItem({
    required this.icon,
    required this.label,
    this.showDot = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF2A2A2A),
              ),
              child: Icon(icon, color: Colors.white70),
            ),
            if (showDot)
              const Positioned(
                right: 6,
                top: 6,
                child: CircleAvatar(radius: 4, backgroundColor: Colors.red),
              ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 60,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTypography.caption4.copyWith(
              color: AppColors.semanticGrayNeutralBgWhite,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
