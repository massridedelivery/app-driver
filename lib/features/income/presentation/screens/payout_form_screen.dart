import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:massdrive/common/widgets/appbar/base_appbar.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/navigation/app_navigator.dart';
import 'package:massdrive/features/document_registration/presentation/screens/bank_account_form_screen.dart';
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

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    final success = await ref
        .read(walletControllerProvider.notifier)
        .requestPayout(amount);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'โอนเงิน ฿${amount.toStringAsFixed(0)} สำเร็จ',
            style: AppTypography.label2.copyWith(color: Colors.white),
          ),
          backgroundColor: AppColors.semanticSupportMintBgHigh,
        ),
      );
    } else {
      final error = ref.read(walletControllerProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.isNotEmpty ? error : 'โอนเงินไม่สำเร็จ กรุณาลองใหม่อีกครั้ง',
            style: AppTypography.label2.copyWith(color: Colors.white),
          ),
          backgroundColor: AppColors.semanticErrorBgHigh,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletState = ref.watch(walletControllerProvider);
    final bankInfo = walletState.bankAccountInfo;

    return Scaffold(
      appBar: CommonAppBar(titleText: 'โอนเงินไปยังบัญชี', showLeftIcon: true),
      backgroundColor: AppColors.semanticGrayNeutralFgHigh,
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
                          color: Colors.white70,
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
                            color: AppColors.foundationAlphaWhite400,
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
                      color: AppColors.foundationAlphaWhite100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.foundationAlphaWhite200,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'บัญชีธนาคารสำหรับรับเงิน',
                          style: AppTypography.caption4.copyWith(
                            color: AppColors.foundationAlphaWhite400,
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
                                    bankInfo.bankName,
                                    style: AppTypography.caption3.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'เลขที่บัญชี: ${bankInfo.accountNumber.length >= 4 ? "xxxxxx${bankInfo.accountNumber.substring(bankInfo.accountNumber.length - 4)}" : bankInfo.accountNumber}',
                                    style: AppTypography.caption4.copyWith(
                                      color: AppColors.foundationAlphaWhite400,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'ชื่อบัญชี: ${bankInfo.accountName}',
                                    style: AppTypography.caption4.copyWith(
                                      color: AppColors.foundationAlphaWhite400,
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
                      return 'กรุณากรอกจำนวนเงิน';
                    }
                    if (amount > widget.availableBalance) {
                      return 'ยอดเงินไม่เพียงพอ';
                    }
                    if (amount < 100) {
                      return 'ถอนเงินขั้นต่ำ ฿100';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 12),
                Text(
                  'ขั้นต่ำ ฿100 | สูงสุด ฿${widget.availableBalance.toStringAsFixed(0)}',
                  style: AppTypography.caption5.copyWith(
                    color: AppColors.foundationAlphaWhite400,
                  ),
                ),

                const Spacer(),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: (_isSubmitting || bankInfo == null) ? null : _submit,
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
                            'ยืนยันการโอนเงิน',
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
