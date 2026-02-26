import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:massdrive/common/widgets/appbar/base_appbar.dart';
import 'package:massdrive/common/widgets/indicator/wave_dot_indicator.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_routes.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/navigation/app_navigator.dart';
import 'package:massdrive/features/history/presentation/screens/history_screen.dart';
import 'package:massdrive/features/income/presentation/controllers/wallet_controller.dart';
import 'package:massdrive/features/income/presentation/screens/widgets/completed_trips_tile.dart';
import 'package:massdrive/features/income/presentation/screens/widgets/earnings_section.dart';

class IncomeScreen extends ConsumerStatefulWidget {
  const IncomeScreen({super.key});

  @override
  ConsumerState<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends ConsumerState<IncomeScreen>
    with TickerProviderStateMixin {
  late bool isNavigateToConsent = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(titleText: 'รายได้', showLeftIcon: true),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 18,
              childAspectRatio: 1.2,
              children: [
                WalletGridItem(
                  icon: Icons.attach_money,
                  iconBgColor: AppColors.foundationOrange700,
                  title: 'กระเป๋าเงินสด',
                  amount: '฿ 100',
                  onTap: () => context.push(AppRoutes.cashWalletNamedPage),
                ),
                WalletGridItem(
                  icon: Icons.work,
                  iconBgColor: AppColors.semanticGrayNeutralBgWhite,
                  iconColor: AppColors.foundationOrange700,
                  title: 'กระเป๋าเครดิต',
                  amount: '฿ 200',
                  onTap: () => context.push(AppRoutes.creditWalletNamedPage),
                ),
              ],
            ),
            EarningsSection(),
            const SizedBox(height: 16),
            CompletedTripsTile(
              totalTrips: 10,
              onTap: () {
                AppNavigator.push(context, const HistoryScreen());
              },
            ),
          ],
        ),
      ),
      backgroundColor: AppColors.semanticGrayNeutralFgHigh,
    );
  }
}

class WalletGridItem extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String title;
  final String amount;
  final VoidCallback onTap;

  const WalletGridItem({
    super.key,
    required this.icon,
    required this.iconBgColor,
    this.iconColor = AppColors.semanticGrayNeutralBgWhite,
    required this.title,
    required this.amount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [Color(0xFF2F2F2F), Color(0xFF1C1C1C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 55,
              height: 55,
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(height: 12),

            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.heading5.copyWith(
                color: AppColors.semanticGrayNeutralBgWhite,
              ),
            ),

            Text(
              amount,
              style: AppTypography.caption3.copyWith(
                color: AppColors.semanticGrayNeutralBgWhite,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
