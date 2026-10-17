import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:massdrive/common/widgets/appbar/base_appbar.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/theme/app_palette.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/navigation/app_navigator.dart';
import 'package:massdrive/features/document_registration/presentation/screens/bank_account_form_screen.dart';
import 'package:massdrive/features/income/domain/models/payout.dart';
import 'package:massdrive/features/income/presentation/controllers/wallet_controller.dart';
import 'package:massdrive/core/utils/baht.dart';

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
  void initState() {
    super.initState();
    // Limits and today's count change server-side (other requests, admin
    // deletions) — read them fresh every time the form opens.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(walletControllerProvider.notifier).fetchPayoutSummary(),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    final (:receipt, :error) = await ref
        .read(walletControllerProvider.notifier)
        .requestPayout(amount);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (error == null) {
      final net = receipt?.netAmount;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            // A request, not a completed transfer — an admin approves and
            // transfers it (usually within 1–2 business days).
            // Mention what reaches the bank only if it differs (a tax).
            net == null || net == amount
                ? 'ส่งคำขอถอนเงิน ${formatBaht(amount)} แล้ว รอการอนุมัติ'
                : 'ส่งคำขอถอนเงิน ${formatBaht(amount)} แล้ว · ได้รับ ${formatBaht(net)} · รอการอนุมัติ',
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

  /// What the driver will receive for a valid amount. Withholding tax is
  /// shown only if the summary's `wht_rate` is above 0 — today it is 0, so the
  /// driver gets the full amount.
  Widget _buildWhtBreakdown(PayoutLimits limits) {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null ||
        limits.amountError(amount, availableBalance: widget.availableBalance) !=
            null) {
      return const SizedBox.shrink();
    }
    final wht = limits.whtFor(amount);
    final net = limits.netFor(amount);
    final pct = (limits.whtRate * 100).toStringAsFixed(
      limits.whtRate * 100 % 1 == 0 ? 0 : 1,
    );
    final withholds = wht > 0;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.palette.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          if (withholds) ...[
            _whtRow('ยอดถอน', formatBaht(amount)),
            const SizedBox(height: 6),
            _whtRow('หัก ณ ที่จ่าย ($pct%)', '−${formatBaht(wht)}'),
            Divider(height: 16, color: context.palette.border),
            _whtRow('ยอดรับสุทธิ', formatBaht(net), highlight: true),
          ] else
            _whtRow('ยอดที่จะได้รับ', formatBaht(net), highlight: true),
          const SizedBox(height: 8),
          Text(
            withholds
                ? 'หักภาษี ณ ที่จ่ายเมื่อโอนสำเร็จ · โอนภายใน 1–2 วันทำการหลังอนุมัติ'
                : 'ได้รับเต็มจำนวน · โอนภายใน 1–2 วันทำการหลังอนุมัติ',
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
                        formatBaht(widget.availableBalance),
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
                  // Baht with up to 2 decimals (e.g. 1, 0.5, 120.75).
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                  ],
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
                  validator: (value) => _limits.amountError(
                    double.tryParse(value ?? ''),
                    availableBalance: widget.availableBalance,
                  ),
                ),

                const SizedBox(height: 12),
                Text(
                  'ถอนได้อีก ${limits.remainingToday} ครั้งวันนี้ · สูงสุด ${formatBaht(limits.maxWithdraw)}/ครั้ง',
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
