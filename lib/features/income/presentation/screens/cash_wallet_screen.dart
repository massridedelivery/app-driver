import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:massdrive/common/widgets/appbar/base_appbar.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_spacing.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/navigation/app_navigator.dart';
import 'package:massdrive/features/income/presentation/controllers/wallet_controller.dart';
import 'package:massdrive/features/income/presentation/screens/payout_form_screen.dart';
import 'package:massdrive/features/income/presentation/screens/transaction_history_screen.dart';
import 'package:massdrive/features/income/presentation/screens/widgets/wallet_action_tile.dart';
import 'package:shimmer/shimmer.dart';

class CashWalletScreen extends ConsumerWidget {
  const CashWalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(walletControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.semanticGrayNeutralFgHigh,
      appBar: CommonAppBar(
        titleText: 'กระเป๋าเงินสด',
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
                          _buildPremiumBillIllustration(),
                          const SizedBox(height: 24),
                          Text(
                            'ยอดเงินสดที่ถอนได้',
                            style: AppTypography.caption4.copyWith(
                              color: AppColors.semanticGrayNeutralBgWhite
                                  .withOpacity(0.6),
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '฿${state.cashBalance.toStringAsFixed(2)}',
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
                          title: 'โอนไปยังบัญชี',
                          icon: Icons.account_balance_wallet_outlined,
                          onTap: () {
                            if (state.cashBalance <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('ไม่มียอดเงินสดที่สามารถถอนได้'),
                                  backgroundColor: AppColors.semanticErrorBgHigh,
                                ),
                              );
                              return;
                            }
                            AppNavigator.push(
                              context,
                              PayoutFormScreen(
                                availableBalance: state.cashBalance,
                              ),
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
                                title: 'ประวัติกระเป๋าเงินสด',
                                transactionType: 'payout',
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
              itemCount: 2,
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

  Widget _buildPremiumBillIllustration() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Transform.rotate(
          angle: -0.1,
          child: Container(
            width: 120,
            height: 65,
            decoration: BoxDecoration(
              color: AppColors.foundationGreen500.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.foundationGreen500.withOpacity(0.5),
              ),
            ),
          ),
        ),
        Container(
          width: 120,
          height: 65,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.foundationGreen600,
                AppColors.foundationGreen800,
              ],
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: AppColors.foundationGreen700.withOpacity(0.4),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Center(
            child: Icon(Icons.attach_money, color: Colors.white, size: 32),
          ),
        ),
      ],
    );
  }
}

