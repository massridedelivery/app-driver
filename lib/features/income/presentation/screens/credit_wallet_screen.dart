import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:massdrive/common/widgets/appbar/base_appbar.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_spacing.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/navigation/app_navigator.dart';
import 'package:massdrive/features/income/presentation/controllers/wallet_controller.dart';
import 'package:massdrive/features/income/presentation/screens/topup_form_screen.dart';
import 'package:massdrive/features/income/presentation/screens/transaction_history_screen.dart';
import 'package:massdrive/features/income/presentation/screens/widgets/wallet_action_tile.dart';

class CreditWalletScreen extends ConsumerWidget {
  const CreditWalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(walletControllerProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CommonAppBar(
        titleText: 'เครดิตวอลเล็ต',
        showLeftIcon: true,
        onLeftTap: () => context.pop(),
      ),
      body: Container(
        color: AppColors.semanticGrayNeutralFgHigh,
        child: SafeArea(
          child: Column(
            children: [
              // Glass Balance Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s5),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      _buildPremiumMassIllustration(),
                      const SizedBox(height: 24),
                      Text(
                        'ยอดเครดิตในระบบ',
                        style: AppTypography.caption4.copyWith(
                          color: AppColors.semanticGrayNeutralBgWhite,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '฿${state.creditBalance.toStringAsFixed(0)}',
                        style: AppTypography.heading1.copyWith(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Action List
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    WalletActionTile(
                      title: 'เติมเงินทันที',
                      icon: Icons.bolt_rounded,
                      showBadge: true,
                      badgeText: 'ใหม่',
                      onTap: () {
                        AppNavigator.push(
                          context,
                          const TopupFormScreen(),
                        );
                      },
                    ),
                    WalletActionTile(
                      title: 'เติมเงินโดยใช้บัญชี',
                      icon: Icons.account_balance_rounded,
                      onTap: () {
                        AppNavigator.push(
                          context,
                          const TopupFormScreen(),
                        );
                      },
                    ),
                    WalletActionTile(
                      title: 'เติมเงินโดยใช้ PIN',
                      icon: Icons.password_rounded,
                      onTap: () {
                        AppNavigator.push(
                          context,
                          const TopupFormScreen(),
                        );
                      },
                    ),
                    WalletActionTile(
                      title: 'ตรวจสอบประวัติการโอนเงิน',
                      icon: Icons.history_rounded,
                      onTap: () {
                        AppNavigator.push(
                          context,
                          const TransactionHistoryScreen(
                            title: 'ประวัติกระเป๋าเครดิต',
                            transactionType: 'topup',
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumMassIllustration() {
    return Center(
      child: Container(
        width: 120,
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Mass',
              style: AppTypography.heading3.copyWith(
                color: AppColors.foundationGreen600,
                letterSpacing: -1,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
              ),
            ),
            Container(
              width: 40,
              height: 3,
              decoration: BoxDecoration(
                color: AppColors.foundationGreen600,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
