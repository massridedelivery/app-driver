import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:massdrive/common/widgets/appbar/base_appbar.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_spacing.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/features/income/presentation/controllers/wallet_controller.dart';
import 'package:massdrive/features/income/presentation/screens/widgets/wallet_action_tile.dart';

class CashWalletScreen extends ConsumerWidget {
  const CashWalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(walletControllerProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CommonAppBar(
        titleText: 'กระเป๋าเงินสด',
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
                        '฿${state.cashBalance}',
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
                      onTap: () {},
                    ),
                    WalletActionTile(
                      title: 'ตรวจสอบประวัติการโอนเงิน',
                      icon: Icons.history_rounded,
                      onTap: () {},
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
