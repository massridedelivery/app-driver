import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:massdrive/common/widgets/appbar/base_appbar.dart';
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
  @override
  Widget build(BuildContext context) {
    final walletState = ref.watch(walletControllerProvider);

    return Scaffold(
      appBar: CommonAppBar(titleText: 'รายได้', showLeftIcon: true),
      body: walletState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => ref.read(walletControllerProvider.notifier).fetchAll(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Balance Card ────────────────────────────────
                    _BalanceCard(
                      balance: walletState.balance,
                      currency: walletState.currency,
                      isVerified: walletState.isVerified,
                      lastUpdated: walletState.lastUpdated,
                    ),
                    const SizedBox(height: 16),

                    // ── Wallet Type Grid ─────────────────────────────
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
                          amount: '฿${walletState.balance.toStringAsFixed(0)}',
                          onTap: () => context.push(AppRoutes.cashWalletNamedPage),
                        ),
                        WalletGridItem(
                          icon: Icons.work,
                          iconBgColor: AppColors.semanticGrayNeutralBgWhite,
                          iconColor: AppColors.foundationOrange700,
                          title: 'กระเป๋าเครดิต',
                          amount: '฿${walletState.balance.toStringAsFixed(0)}',
                          onTap: () => context.push(AppRoutes.creditWalletNamedPage),
                        ),
                      ],
                    ),

                    // ── Earnings Section ─────────────────────────────
                    EarningsSection(
                      earningsToday: walletState.earningsToday,
                      earningsWeek: walletState.earningsWeek,
                    ),
                    const SizedBox(height: 16),

                    // ── Trips Today ──────────────────────────────────
                    CompletedTripsTile(
                      totalTrips: walletState.totalTripsToday,
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
        ? DateFormat('dd MMM yyyy HH:mm', 'th_TH').format(lastUpdated!.toLocal())
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
                'ยอดเงินรวม',
                style: AppTypography.caption4.copyWith(
                  color: AppColors.semanticGrayNeutralFgMidOnWhite,
                ),
              ),
              if (isVerified) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E6B3C),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified, color: Colors.greenAccent, size: 12),
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
