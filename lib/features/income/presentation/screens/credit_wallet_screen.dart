import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:massdrive/common/widgets/appbar/base_appbar.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_spacing.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/navigation/app_navigator.dart';
import 'package:massdrive/features/income/presentation/controllers/wallet_controller.dart';
import 'package:massdrive/features/income/presentation/screens/settle_debt_form_screen.dart';
import 'package:massdrive/features/income/presentation/screens/transaction_history_screen.dart';
import 'package:massdrive/features/income/presentation/screens/widgets/wallet_action_tile.dart';
import 'package:shimmer/shimmer.dart';

class CreditWalletScreen extends ConsumerWidget {
  const CreditWalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(walletControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.semanticGrayNeutralFgHigh,
      appBar: CommonAppBar(
        titleText: 'เครดิตวอลเล็ต',
        showLeftIcon: true,
      ),
      body: SafeArea(
        child: state.isLoading
            ? _buildSkeletonLoading()
            : Column(
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
                            'ยอดค้างชำระ',
                            style: AppTypography.caption4.copyWith(
                              color: AppColors.semanticGrayNeutralBgWhite,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '฿${state.balance.abs().toStringAsFixed(0)}',
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
                          title: 'ชำระเงินทาง PromptPay',
                          icon: Icons.bolt_rounded,
                          showBadge: true,
                          badgeText: 'ใหม่',
                          onTap: () {
                            AppNavigator.push(
                              context,
                              const SettleDebtFormScreen(paymentMethod: 'PROMPTPAY'),
                            );
                          },
                        ),
                        WalletActionTile(
                          title: 'โอนเงินเข้าบัญชี (Manual)',
                          icon: Icons.account_balance_rounded,
                          onTap: () {
                            AppNavigator.push(
                              context,
                              const SettleDebtFormScreen(paymentMethod: 'MANUAL'),
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
    );
  }

  Widget _buildSkeletonLoading() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF1E2F38),
      highlightColor: const Color(0xFF2C3E4A),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s5),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  Container(
                    width: 120,
                    height: 65,
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: 140,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: 120,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 4,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Colors.white12,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      width: 180,
                      height: 18,
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
