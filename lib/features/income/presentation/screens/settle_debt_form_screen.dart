import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:massdrive/common/widgets/appbar/base_appbar.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/navigation/app_navigator.dart';
import 'package:massdrive/features/income/presentation/controllers/wallet_controller.dart';
import 'package:massdrive/features/income/presentation/screens/settle_debt_slip_form_screen.dart';

class SettleDebtFormScreen extends ConsumerStatefulWidget {
  final String paymentMethod; // "PROMPTPAY" or "MANUAL"

  const SettleDebtFormScreen({super.key, required this.paymentMethod});

  @override
  ConsumerState<SettleDebtFormScreen> createState() => _SettleDebtFormScreenState();
}

class _SettleDebtFormScreenState extends ConsumerState<SettleDebtFormScreen> {
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  Map<String, dynamic>? _settleResult;

  final _quickAmounts = [100, 200, 300, 500, 1000];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    final result = await ref
        .read(walletControllerProvider.notifier)
        .settleDebt(amount: amount, paymentMethod: widget.paymentMethod);

    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
      _settleResult = result;
    });

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'ดำเนินการไม่สำเร็จ กรุณาลองใหม่อีกครั้ง',
            style: AppTypography.label2.copyWith(color: Colors.white),
          ),
          backgroundColor: AppColors.semanticErrorBgHigh,
        ),
      );
      return;
    }

    if (widget.paymentMethod == 'MANUAL') {
      final intentId = result['intent_id']?.toString() ?? '';
      final bankDetails = result['bank_details'] as Map<String, dynamic>? ?? {};
      // Navigate to slip upload form screen
      AppNavigator.pushReplacement(
        context,
        SettleDebtSlipFormScreen(
          intentId: intentId,
          amount: amount,
          bankDetails: bankDetails,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_settleResult != null && widget.paymentMethod == 'PROMPTPAY') {
      return _buildQRScreen(_settleResult!);
    }

    final balance = ref.watch(walletControllerProvider).balance;
    final maxAmount = balance.abs();

    return Scaffold(
      appBar: CommonAppBar(
        titleText: widget.paymentMethod == 'PROMPTPAY' ? 'ชำระเงินทาง PromptPay' : 'โอนเงินเข้าบัญชี (Manual)',
        showLeftIcon: true,
      ),
      backgroundColor: AppColors.semanticGrayNeutralFgHigh,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'จำนวนเงินที่ต้องการชำระ',
                  style: AppTypography.caption3.copyWith(
                    color: AppColors.semanticGrayNeutralBgWhite,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: AppTypography.heading3.copyWith(color: Colors.white),
                  decoration: InputDecoration(
                    prefixText: '฿ ',
                    prefixStyle: AppTypography.heading3.copyWith(
                      color: Colors.white70,
                    ),
                    hintText: '0',
                    hintStyle: AppTypography.heading3.copyWith(
                      color: Colors.white30,
                    ),
                    filled: true,
                    fillColor: AppColors.foundationAlphaWhite100,
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
                      return 'กรุณากรอกจำนวนเงินมากกว่า 0';
                    }
                    if (amount > maxAmount) {
                      return 'จำนวนเงินต้องไม่เกินยอดค้างชำระ (฿${maxAmount.toStringAsFixed(0)})';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Quick Amount Chips
                Text(
                  'เลือกจำนวนด่วน',
                  style: AppTypography.caption4.copyWith(
                    color: AppColors.foundationAlphaWhite400,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _quickAmounts.where((a) => a <= maxAmount).map((amount) {
                    return GestureDetector(
                      onTap: () {
                        _amountController.text = amount.toString();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.foundationAlphaWhite100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.foundationOrange700.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                        child: Text(
                          '฿$amount',
                          style: AppTypography.caption4.copyWith(
                            color: AppColors.foundationOrange500,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 12),
                Text(
                  'ยอดค้างชำระทั้งหมด: ฿${maxAmount.toStringAsFixed(2)}',
                  style: AppTypography.caption5.copyWith(
                    color: AppColors.foundationAlphaWhite400,
                  ),
                ),

                const Spacer(),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: (_isSubmitting || maxAmount <= 0) ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.foundationOrange600,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      elevation: 0,
                    ),
                    child: _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'ดำเนินการชำระหนี้',
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

  Widget _buildQRScreen(Map<String, dynamic> result) {
    final intentId = result['intent_id']?.toString() ?? '';
    final status = result['status']?.toString() ?? 'PENDING';
    final qrCodeUrl = result['qr_code_url']?.toString() ?? '';

    return Scaffold(
      appBar: CommonAppBar(titleText: 'สแกน QR เพื่อชำระ', showLeftIcon: true),
      backgroundColor: AppColors.semanticGrayNeutralFgHigh,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F3B66),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.qr_code_scanner, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'THAI QR PAYMENT',
                      style: AppTypography.heading5.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: qrCodeUrl.isNotEmpty
                      ? Image.network(
                          qrCodeUrl,
                          width: 180,
                          height: 180,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.qr_code, size: 160, color: Colors.black),
                        )
                      : const Icon(Icons.qr_code, size: 160, color: Colors.black),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'หมายเลขรายการ: $intentId',
                style: AppTypography.caption4.copyWith(
                  color: AppColors.foundationAlphaWhite400,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.semanticWarningBorderHigh.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status == 'PENDING' ? 'รอชำระเงิน' : status,
                  style: AppTypography.caption4.copyWith(
                    color: AppColors.semanticWarningBorderHigh,
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.foundationAlphaWhite100,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'กลับหน้ากระเป๋าเงิน',
                    style: AppTypography.heading5.copyWith(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
