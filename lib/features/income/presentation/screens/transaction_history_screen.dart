import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:massdrive/common/widgets/appbar/base_appbar.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/features/income/presentation/controllers/wallet_controller.dart';

class TransactionHistoryScreen extends ConsumerStatefulWidget {
  final String title;
  final String? transactionType;

  const TransactionHistoryScreen({
    super.key,
    this.title = 'ประวัติการโอนเงิน',
    this.transactionType,
  });

  @override
  ConsumerState<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState
    extends ConsumerState<TransactionHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(walletControllerProvider.notifier)
          .fetchTransactions(type: widget.transactionType);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(walletControllerProvider);

    return Scaffold(
      appBar: CommonAppBar(titleText: widget.title, showLeftIcon: true),
      backgroundColor: AppColors.semanticGrayNeutralFgHigh,
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.transactions.isEmpty
          ? _buildEmptyState()
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.transactions.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final tx = state.transactions[index];
                return _TransactionTile(transaction: tx);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: AppColors.foundationAlphaWhite400,
          ),
          const SizedBox(height: 16),
          Text(
            'ไม่มีประวัติการทำรายการ',
            style: AppTypography.caption3.copyWith(
              color: AppColors.foundationAlphaWhite400,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Map<String, dynamic> transaction;

  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final type = transaction['type']?.toString() ?? '';
    final amount = (transaction['amount'] as num?)?.toDouble() ?? 0.0;
    final status = transaction['status']?.toString() ?? '';
    final description = transaction['description']?.toString() ?? '';
    final createdAt = transaction['created_at'] != null
        ? DateTime.tryParse(transaction['created_at'].toString())
        : null;

    final isCredit = type == 'topup' || type == 'earning';
    final amountColor = isCredit
        ? AppColors.semanticSupportMintBgHigh
        : AppColors.semanticErrorFgHigh;
    final amountPrefix = isCredit ? '+' : '-';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.foundationAlphaWhite100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isCredit
                  ? AppColors.semanticSupportMintBgHigh.withOpacity(0.15)
                  : AppColors.semanticErrorFgHigh.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCredit ? Icons.arrow_downward : Icons.arrow_upward,
              color: amountColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: AppTypography.caption3.copyWith(
                    color: AppColors.semanticGrayNeutralBgWhite,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (createdAt != null)
                      Text(
                        DateFormat('d MMM yyyy, HH:mm').format(createdAt),
                        style: AppTypography.caption5.copyWith(
                          color: AppColors.foundationAlphaWhite400,
                        ),
                      ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: status == 'completed'
                            ? AppColors.semanticSupportMintBgHigh.withOpacity(
                                0.15,
                              )
                            : AppColors.semanticWarningBorderHigh.withOpacity(
                                0.15,
                              ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        status == 'completed' ? 'สำเร็จ' : 'รอดำเนินการ',
                        style: AppTypography.caption5.copyWith(
                          color: status == 'completed'
                              ? AppColors.semanticSupportMintBgHigh
                              : AppColors.semanticWarningBorderHigh,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            '$amountPrefix฿${amount.toStringAsFixed(0)}',
            style: AppTypography.caption3.copyWith(
              color: amountColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
