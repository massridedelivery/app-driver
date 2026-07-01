import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:massdrive/common/widgets/appbar/base_appbar.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/navigation/app_navigator.dart';
import 'package:massdrive/features/history/presentation/screens/history_screen.dart';
import 'package:massdrive/features/income/presentation/controllers/wallet_controller.dart';
import 'package:massdrive/features/income/presentation/screens/credit_wallet_screen.dart';
import 'package:massdrive/features/income/presentation/screens/widgets/completed_trips_tile.dart';

class IncomeScreen extends ConsumerStatefulWidget {
  const IncomeScreen({super.key});

  @override
  ConsumerState<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends ConsumerState<IncomeScreen>
    with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    final walletState = ref.watch(walletControllerProvider);
    final creditDiff = walletState.codThreshold - walletState.currentBalance;
    final creditAmount = creditDiff < 0
        ? '฿${creditDiff.abs().toStringAsFixed(2)}'
        : '฿${creditDiff.toStringAsFixed(2)}';

    return Scaffold(
      appBar: CommonAppBar(titleText: 'รายได้', showLeftIcon: true),
      body: walletState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () =>
                  ref.read(walletControllerProvider.notifier).fetchAll(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Balance Card ────────────────────────────────
                    _BalanceCard(
                      balance: walletState.currentBalance,
                      currency: walletState.currency,
                      isVerified: walletState.isVerified,
                      lastUpdated: walletState.lastUpdated,
                    ),
                    const SizedBox(height: 16),

                    // ── Credit Wallet Card ───────────────────────────
                    CreditWalletCard(
                      amount: creditAmount,
                      onTap: () => AppNavigator.push(
                        context,
                        const CreditWalletScreen(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Trips Today ──────────────────────────────────
                    CompletedTripsTile(
                      onTap: () {
                        AppNavigator.push(context, const HistoryScreen());
                      },
                    ),
                  ],
                ),
              ),
            ),
      backgroundColor: AppColors.semanticGrayNeutralFgHigh,
    );
  }
}

class CreditWalletCard extends StatelessWidget {
  final String amount;
  final VoidCallback onTap;

  const CreditWalletCard({
    super.key,
    required this.amount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
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
        child: Row(
          children: [
            Container(
              width: 55,
              height: 55,
              decoration: const BoxDecoration(
                color: AppColors.semanticGrayNeutralBgWhite,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.work,
                color: AppColors.foundationOrange700,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'กระเป๋าเครดิต',
                    style: AppTypography.heading5.copyWith(
                      color: AppColors.semanticGrayNeutralBgWhite,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'แตะเพื่อชำระหนี้ค้างชำระ',
                    style: AppTypography.caption4.copyWith(
                      color: AppColors.semanticGrayNeutralFgMidOnWhite,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              amount,
              style: AppTypography.heading4.copyWith(
                color: AppColors.semanticGrayNeutralBgWhite,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.semanticGrayNeutralFgMidOnWhite,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _BalanceCard — shows unified balance from GET /api/driver/earnings
// ─────────────────────────────────────────────────────────────────────────────
class _BalanceCard extends StatelessWidget {
  final double balance;
  final String currency;
  final bool isVerified;
  final DateTime? lastUpdated;

  const _BalanceCard({
    required this.balance,
    required this.currency,
    required this.isVerified,
    this.lastUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final formattedBalance = NumberFormat('#,##0.00', 'th_TH').format(balance);
    final formattedDate = lastUpdated != null
        ? DateFormat(
            'dd MMM yyyy HH:mm',
            'th_TH',
          ).format(lastUpdated!.toLocal())
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF2F2F2F), Color(0xFF1A1A1A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row with verified badge
          Row(
            children: [
              Text(
                'ยอดค้างชำระ',
                style: AppTypography.caption4.copyWith(
                  color: AppColors.semanticGrayNeutralFgMidOnWhite,
                ),
              ),
              if (isVerified) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E6B3C),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.verified,
                        color: Colors.greenAccent,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'ยืนยันแล้ว',
                        style: AppTypography.caption4.copyWith(
                          color: Colors.greenAccent,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 8),

          // Balance amount
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '฿$formattedBalance',
                style: AppTypography.heading2.copyWith(
                  color: AppColors.semanticGrayNeutralBgWhite,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  currency,
                  style: AppTypography.caption4.copyWith(
                    color: AppColors.semanticGrayNeutralFgMidOnWhite,
                  ),
                ),
              ),
            ],
          ),

          // Last updated
          if (formattedDate != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 12,
                  color: AppColors.semanticGrayNeutralFgMidOnWhite,
                ),
                const SizedBox(width: 4),
                Text(
                  'อัปเดต: $formattedDate',
                  style: AppTypography.caption4.copyWith(
                    color: AppColors.semanticGrayNeutralFgMidOnWhite,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
