import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:massdrive/common/widgets/appbar/base_appbar.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/theme/app_palette.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/navigation/app_navigator.dart';
import 'package:massdrive/features/document_registration/presentation/screens/bank_account_form_screen.dart';
import 'package:massdrive/features/income/domain/models/payout.dart';
import 'package:massdrive/features/income/presentation/controllers/wallet_controller.dart';

class PayoutFormScreen extends ConsumerStatefulWidget {
  final double availableBalance;

  const PayoutFormScreen({super.key, required this.availableBalance});

  @override
  ConsumerState<PayoutFormScreen> createState() => _PayoutFormScreenState();
}

class _PayoutFormScreenState extends ConsumerState<PayoutFormScreen> {
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  /// Withdrawal rules from GET /api/driver/payouts/summary.
  PayoutLimits get _limits => ref.read(walletControllerProvider).payoutLimits;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    final error = await ref
        .read(walletControllerProvider.notifier)
        .requestPayout(amount);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (error == null) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            // A request, not a completed transfer — an admin approves and
            // transfers it (usually within 1–2 business days).
            'ส่งคำขอถอนเงิน ฿${amount.toStringAsFixed(0)} แล้ว รอการอนุมัติ',
            style: AppTypography.label2.copyWith(color: Colors.white),
          ),
          backgroundColor: AppColors.semanticSupportMintBgHigh,
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error.message,
          style: AppTypography.label2.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.semanticErrorBgHigh,
        action: error.needsBankAccount
            ? SnackBarAction(
                label: 'แก้ไขบัญชี',
                textColor: Colors.white,
                onPressed: () =>
                    AppNavigator.push(context, const BankAccountFormScreen()),
              )
            : null,
      ),
    );
  }

  /// Withholding-tax breakdown: the backend deducts `wht_rate` when the
  /// transfer completes, so the driver receives the net. Shown once the amount
  /// is valid.
  Widget _buildWhtBreakdown(PayoutLimits limits) {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    if (amount < limits.minWithdraw ||
        amount > limits.maxWithdraw ||
        amount > widget.availableBalance) {
      return const SizedBox.shrink();
    }
    final net = limits.netFor(amount);
    final wht = amount - net;
    final pct = (limits.whtRate * 100).toStringAsFixed(
      limits.whtRate * 100 % 1 == 0 ? 0 : 1,
    );
    final fmt = NumberFormat('#,##0');

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.palette.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _whtRow('ยอดถอน', '฿${fmt.format(amount)}'),
          const SizedBox(height: 6),
          _whtRow('หัก ณ ที่จ่าย ($pct%)', '−฿${fmt.format(wht)}'),
          Divider(height: 16, color: context.palette.border),
          _whtRow('ยอดรับสุทธิ', '฿${fmt.format(net)}', highlight: true),
          const SizedBox(height: 8),
          Text(
            'หักภาษี ณ ที่จ่ายเมื่อโอนสำเร็จ · โอนภายใน 1–2 วันทำการหลังอนุมัติ',
            style: AppTypography.caption5.copyWith(
              color: context.palette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _whtRow(String label, String value, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.caption4
              .copyWith(color: context.palette.textSecondary),
        ),
        Text(
          value,
          style: AppTypography.caption3.copyWith(
            color: highlight ? AppColors.foundationGreen500 : context.palette.textPrimary,
            fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final walletState = ref.watch(walletControllerProvider);
    final bankInfo = walletState.bankAccountInfo;
    final limits = walletState.payoutLimits;
    final blockReason =
        limits.blockReason(availableBalance: widget.availableBalance);

    return Scaffold(
      appBar: CommonAppBar(titleText: 'โอนเงินไปยังบัญชี', showLeftIcon: true),
      backgroundColor: context.palette.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Balance Info Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.foundationGreen700,
                        AppColors.foundationGreen900,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ยอดเงินที่ถอนได้',
                        style: AppTypography.caption4.copyWith(
                          color: AppColors.foundationAlphaWhite400,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '฿${widget.availableBalance.toStringAsFixed(0)}',
                        style: AppTypography.heading2.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Bank Account Info Block or Warning Card
                if (bankInfo == null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.semanticErrorBgHigh.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.semanticErrorBgHigh.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: AppColors.semanticErrorBgHigh),
                            const SizedBox(width: 8),
                            Text(
                              'ยังไม่ได้ผูกบัญชีธนาคารสำหรับรับเงิน',
                              style: AppTypography.caption3.copyWith(
                                color: AppColors.semanticErrorBgHigh,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'กรุณาผูกบัญชีธนาคารเพื่อใช้ในการรับเงินโอน',
                          style: AppTypography.caption4.copyWith(
                            color: context.palette.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 36,
                          child: ElevatedButton(
                            onPressed: () {
                              AppNavigator.push(context, const BankAccountFormScreen());
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.semanticErrorBgHigh,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: Text(
                              'ผูกบัญชีธนาคาร',
                              style: AppTypography.caption3.copyWith(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.palette.surfaceAlt,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: context.palette.border,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'บัญชีธนาคารสำหรับรับเงิน',
                          style: AppTypography.caption4.copyWith(
                            color: context.palette.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 18,
                              backgroundColor: AppColors.foundationOrange600,
                              child: Icon(Icons.account_balance_rounded, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    bankInfo.bankLabel,
                                    style: AppTypography.caption3.copyWith(
                                      color: context.palette.textPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'เลขที่บัญชี: ${bankInfo.accountNumber.length >= 4 ? "xxxxxx${bankInfo.accountNumber.substring(bankInfo.accountNumber.length - 4)}" : bankInfo.accountNumber}',
                                    style: AppTypography.caption4.copyWith(
                                      color: context.palette.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'ชื่อบัญชี: ${bankInfo.accountName}',
                                    style: AppTypography.caption4.copyWith(
                                      color: context.palette.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                Text(
                  'จำนวนเงินที่ต้องการโอน',
                  style: AppTypography.caption3.copyWith(
                    color: context.palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: AppTypography.heading3.copyWith(color: context.palette.textPrimary),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    prefixText: '฿ ',
                    prefixStyle: AppTypography.heading3.copyWith(
                      color: context.palette.textSecondary,
                    ),
                    hintText: '0',
                    hintStyle: AppTypography.heading3.copyWith(
                      color: context.palette.textTertiary,
                    ),
                    filled: true,
                    fillColor: context.palette.surfaceAlt,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                  ),
                  validator: (value) {
                    final amount = double.tryParse(value ?? '');
                    if (amount == null || amount <= 0) {
                      return 'กรุณากรอกจำนวนเงิน';
                    }
                    if (amount < _limits.minWithdraw) {
                      return 'ถอนเงินขั้นต่ำ ฿${_limits.minWithdraw.toStringAsFixed(0)}';
                    }
                    if (amount > _limits.maxWithdraw) {
                      return 'ถอนสูงสุด ฿${NumberFormat('#,##0').format(_limits.maxWithdraw)} ต่อครั้ง';
                    }
                    if (amount > widget.availableBalance) {
                      return 'ยอดเงินไม่เพียงพอ';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 12),
                Text(
                  'ขั้นต่ำ ฿${limits.minWithdraw.toStringAsFixed(0)} | สูงสุด ฿${NumberFormat('#,##0').format(limits.maxWithdraw)}/ครั้ง | ไม่เกิน ${limits.maxPerDay} ครั้ง/วัน (วันนี้ ${limits.withdrawalsToday}/${limits.maxPerDay})',
                  style: AppTypography.caption5.copyWith(
                    color: context.palette.textSecondary,
                  ),
                ),

                // Withholding breakdown — shown once a valid amount is entered.
                _buildWhtBreakdown(limits),

                // Why a withdrawal can't be made right now (from the summary),
                // so the driver isn't left guessing why the button is off.
                if (blockReason != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.semanticErrorBgHigh.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            size: 18, color: AppColors.semanticErrorBgHigh),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            blockReason,
                            style: AppTypography.caption4.copyWith(
                              color: context.palette.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const Spacer(),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed:
                        (_isSubmitting || bankInfo == null || blockReason != null)
                            ? null
                            : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.foundationGreen600,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      elevation: 0,
                    ),
                    child: _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'ยืนยันถอนเงิน',
                            style: AppTypography.heading5.copyWith(
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
