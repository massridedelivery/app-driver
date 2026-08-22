import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:massdrive/common/widgets/appbar/base_appbar.dart';
import 'package:massdrive/common/widgets/indicator/mass_loading_m.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/theme/app_palette.dart';
import 'package:massdrive/core/navigation/app_navigator.dart';
import 'package:massdrive/features/income/presentation/controllers/wallet_controller.dart';
import 'package:massdrive/features/income/presentation/screens/cash_wallet_screen.dart';
import 'package:massdrive/features/income/presentation/screens/credit_wallet_screen.dart';
import 'package:massdrive/features/income/presentation/screens/transaction_history_screen.dart';
import 'package:massdrive/features/income/presentation/screens/held_fares_screen.dart';

class IncomeScreen extends ConsumerWidget {
  const IncomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(walletControllerProvider);

    return Scaffold(
      backgroundColor: context.palette.bg,
      appBar: CommonAppBar(titleText: 'รายได้', showLeftIcon: true),
      body: state.isLoading
          ? const Center(child: MassLoadingM(size: 72))
          // Zeros from a failed fetch look exactly like a genuinely empty
          // wallet — say the load failed instead.
          : state.errorMessage.isNotEmpty
          ? _ErrorState(
              message: state.errorMessage,
              onRetry: () =>
                  ref.read(walletControllerProvider.notifier).fetchAll(),
            )
          : RefreshIndicator(
              onRefresh: () =>
                  ref.read(walletControllerProvider.notifier).fetchAll(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                // Clear the Android edge-to-edge system nav at the bottom.
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  16 + MediaQuery.viewPaddingOf(context).bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Today's total earnings ───────────────────────
                    // Shows what the driver earned today, not the running
                    // wallet balance — `state.balance` goes negative on COD
                    // debt, which read as "you have -฿12.83" on the headline.
                    _TotalBalanceCard(
                      balance: state.earningsToday,
                      currency: state.currency,
                      isVerified: state.isVerified,
                      lastUpdated: state.lastUpdated,
                    ),
                    const SizedBox(height: 16),

                    // ── Cash + Credit wallets ────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: _WalletMiniCard(
                            title: 'กระเป๋าเงินสด',
                            amount: state.cashBalance,
                            icon: Icons.attach_money_rounded,
                            iconBg: AppColors.foundationOrange600,
                            iconColor: Colors.white,
                            onTap: () => AppNavigator.push(
                              context,
                              const CashWalletScreen(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _WalletMiniCard(
                            title: 'กระเป๋าเครดิต',
                            amount: state.creditBalance,
                            icon: Icons.work_rounded,
                            iconBg: AppColors.foundationOrange100,
                            iconColor: AppColors.foundationOrange700,
                            onTap: () => AppNavigator.push(
                              context,
                              const CreditWalletScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Earnings (today / week / month / year) carousel ──
                    _EarningsCarousel(
                      today: state.earningsToday,
                      week: state.earningsWeek,
                      month: state.earningsMonth,
                      year: state.earningsYear,
                      currency: state.currency,
                    ),
                    const SizedBox(height: 16),

                    // ── All transactions ─────────────────────────────
                    _AllTransactionsTile(
                      count: state.transactionsTotal,
                      onTap: () => AppNavigator.push(
                        context,
                        const TransactionHistoryScreen(title: 'รายการทั้งหมด'),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // ── Held fares awaiting finance review (SCRUM-86) ──
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.hourglass_bottom,
                          color: context.palette.textSecondary),
                      title: Text(
                        'ค่างานรอตรวจสอบ',
                        style: AppTypography.caption3
                            .copyWith(color: context.palette.textPrimary),
                      ),
                      subtitle: Text(
                        'รายการที่ยืนยันแบบ override รอฝ่ายการเงิน',
                        style: AppTypography.caption4
                            .copyWith(color: context.palette.textSecondary),
                      ),
                      trailing: Icon(Icons.chevron_right,
                          color: context.palette.textTertiary),
                      onTap: () =>
                          AppNavigator.push(context, const HeldFaresScreen()),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error state
// ─────────────────────────────────────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 64,
              color: context.palette.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'โหลดข้อมูลรายได้ไม่สำเร็จ',
              style: AppTypography.heading5.copyWith(color: context.palette.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              message.replaceFirst('Exception: ', ''),
              textAlign: TextAlign.center,
              style: AppTypography.caption4.copyWith(
                color: context.palette.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: context.palette.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'ลองใหม่',
                style: AppTypography.label2.copyWith(color: context.palette.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared card decoration
// ─────────────────────────────────────────────────────────────────────────────
/// Card surface for the income screen. Dark mode keeps the premium dark
/// gradient; light mode flips to a white surface with a hairline border and a
/// soft shadow so the cards read as raised panels on the light background.
BoxDecoration _cardDecoration(BuildContext context, {double radius = 20}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return BoxDecoration(
    borderRadius: BorderRadius.circular(radius),
    color: isDark ? null : context.palette.surface,
    gradient: isDark
        ? const LinearGradient(
            colors: [Color(0xFF2A2A2A), Color(0xFF1A1A1A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : null,
    border: isDark ? null : Border.all(color: context.palette.border),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
        blurRadius: 16,
        offset: const Offset(0, 8),
      ),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Total balance card
// ─────────────────────────────────────────────────────────────────────────────
class _TotalBalanceCard extends StatelessWidget {
  final double balance;
  final String currency;
  final bool isVerified;
  final DateTime? lastUpdated;

  const _TotalBalanceCard({
    required this.balance,
    required this.currency,
    required this.isVerified,
    this.lastUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final formattedBalance = NumberFormat('#,##0', 'th_TH').format(balance);
    final formattedDate = lastUpdated != null
        ? DateFormat('dd MMM yyyy HH:mm', 'th_TH').format(lastUpdated!.toLocal())
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'ยอดเงินรวมวันนี้',
                style: AppTypography.caption4.copyWith(
                  color: context.palette.textSecondary,
                ),
              ),
              if (isVerified) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                        style: AppTypography.caption4
                            .copyWith(color: Colors.greenAccent, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '฿$formattedBalance',
                style: AppTypography.heading2.copyWith(
                  color: context.palette.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  currency,
                  style: AppTypography.caption4.copyWith(
                    color: context.palette.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          if (formattedDate != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time_rounded,
                    size: 12, color: context.palette.textSecondary),
                const SizedBox(width: 4),
                Text(
                  'อัปเดต: $formattedDate',
                  style: AppTypography.caption4.copyWith(
                    color: context.palette.textSecondary,
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

// ─────────────────────────────────────────────────────────────────────────────
// Cash / Credit mini card
// ─────────────────────────────────────────────────────────────────────────────
class _WalletMiniCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final VoidCallback onTap;

  const _WalletMiniCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
        decoration: _cardDecoration(context),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: AppTypography.caption4.copyWith(
                color: context.palette.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '฿${NumberFormat('#,##0', 'th_TH').format(amount)}',
              style: AppTypography.heading5.copyWith(
                color: context.palette.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Earnings carousel (today / this week)
// ─────────────────────────────────────────────────────────────────────────────
class _EarningsCarousel extends StatefulWidget {
  final double today;
  final double week;
  final double month;
  final double year;
  final String currency;

  const _EarningsCarousel({
    required this.today,
    required this.week,
    required this.month,
    required this.year,
    required this.currency,
  });

  @override
  State<_EarningsCarousel> createState() => _EarningsCarouselState();
}

class _EarningsCarouselState extends State<_EarningsCarousel> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      ('รายได้วันนี้', widget.today),
      ('รายได้สัปดาห์นี้', widget.week),
      ('รายได้เดือนนี้', widget.month),
      ('รายได้ปีนี้', widget.year),
    ];

    return Column(
      children: [
        SizedBox(
          // Kept compact — the earnings figure is a one-liner, so a tall card
          // just pushed the transactions list below the fold.
          height: 104,
          child: PageView.builder(
            controller: _controller,
            itemCount: pages.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, index) {
              final (label, amount) = pages[index];
              return _EarningsCard(label: label, amount: amount);
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(pages.length, (i) {
            final active = i == _page;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: active
                    ? AppColors.foundationOrange600
                    : context.palette.border,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _EarningsCard extends StatelessWidget {
  final String label;
  final double amount;

  const _EarningsCard({required this.label, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: _cardDecoration(context),
      child: Stack(
        children: [
          // Decorative faded circle on the right.
          Positioned(
            right: -8,
            top: 4,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.palette.surfaceAlt,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTypography.caption4.copyWith(
                  color: context.palette.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  '฿${NumberFormat('#,##0', 'th_TH').format(amount)}',
                  maxLines: 1,
                  style: AppTypography.heading1.copyWith(
                    color: context.palette.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// All transactions tile
// ─────────────────────────────────────────────────────────────────────────────
class _AllTransactionsTile extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _AllTransactionsTile({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: _cardDecoration(context, radius: 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'รายการทั้งหมด',
                    style: AppTypography.caption4.copyWith(
                      color: context.palette.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$count รายการ',
                    style: AppTypography.heading5.copyWith(
                      color: context.palette.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: context.palette.textPrimary),
          ],
        ),
      ),
    );
  }
}
