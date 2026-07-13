import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:massdrive/common/widgets/appbar/base_appbar.dart';
import 'package:massdrive/common/widgets/qr_image.dart';
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

  // MARK: PromptPay intent polling (SCRUM-35 §4.3)
  static const _pollInterval = Duration(seconds: 3);
  Timer? _pollTimer;
  Timer? _countdownTimer;
  String _intentStatus = 'AWAITING_PAYMENT';
  DateTime? _expiresAt;
  Duration _timeLeft = Duration.zero;

  bool get _isTerminal =>
      _intentStatus == 'PAID' ||
      _intentStatus == 'FAILED' ||
      _intentStatus == 'EXPIRED' ||
      _intentStatus == 'REFUNDED';

  @override
  void dispose() {
    _pollTimer?.cancel();
    _countdownTimer?.cancel();
    _amountController.dispose();
    super.dispose();
  }

  void _cancelTimers() {
    _pollTimer?.cancel();
    _countdownTimer?.cancel();
  }

  /// Kick off the QR flow: start the expiry countdown and status polling.
  void _startPromptPayFlow(Map<String, dynamic> result) {
    _cancelTimers();

    final intentId = result['intent_id']?.toString() ?? '';
    _intentStatus = result['status']?.toString() ?? 'AWAITING_PAYMENT';
    _expiresAt = DateTime.tryParse(result['expires_at']?.toString() ?? '');
    _tick(); // seed _timeLeft immediately

    if (intentId.isEmpty || _isTerminal) return;

    _countdownTimer =
        Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    _pollTimer = Timer.periodic(_pollInterval, (_) => _pollIntent(intentId));
  }

  void _tick() {
    final expiresAt = _expiresAt;
    if (expiresAt == null) return;
    final remaining = expiresAt.difference(DateTime.now());
    if (remaining.isNegative || remaining == Duration.zero) {
      if (!_isTerminal) {
        setState(() => _intentStatus = 'EXPIRED');
      }
      _cancelTimers();
      setState(() => _timeLeft = Duration.zero);
    } else {
      setState(() => _timeLeft = remaining);
    }
  }

  Future<void> _pollIntent(String intentId) async {
    if (_isTerminal) {
      _cancelTimers();
      return;
    }
    final intent = await ref
        .read(walletControllerProvider.notifier)
        .getPaymentIntent(intentId);
    if (!mounted || intent == null) return;

    final status = intent['status']?.toString();
    if (status == null || status == _intentStatus) return;

    setState(() => _intentStatus = status);

    if (status == 'PAID') {
      _cancelTimers();
      // Debt cleared server-side — refresh COD status so the wallet reflects it.
      await ref.read(walletControllerProvider.notifier).fetchCodStatus();
    } else if (status == 'FAILED' ||
        status == 'EXPIRED' ||
        status == 'REFUNDED') {
      _cancelTimers();
    }
  }

  /// Regenerate a fresh QR after expiry/failure (creates a new intent).
  void _regenerate() {
    _cancelTimers();
    setState(() {
      _settleResult = null;
      _intentStatus = 'AWAITING_PAYMENT';
      _expiresAt = null;
      _timeLeft = Duration.zero;
    });
    _submit();
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

    if (result != null && widget.paymentMethod == 'PROMPTPAY') {
      _startPromptPayFlow(result);
    }

    if (result == null) {
      final reason = ref.read(walletControllerProvider).errorMessage;
      final message = reason.isNotEmpty
          ? reason.replaceFirst('Exception: ', '')
          : 'ดำเนินการไม่สำเร็จ กรุณาลองใหม่อีกครั้ง';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
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

    final codDebt = ref.watch(walletControllerProvider).codDebt;
    final maxAmount = codDebt.abs();

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
                      return 'จำนวนเงินต้องไม่เกินยอดค้างชำระ (฿${maxAmount.toStringAsFixed(2)})';
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

  /// Thai label + accent color for each intent status (SCRUM-35 §2.2 enum).
  ({String label, Color color}) _statusDisplay(String status) {
    switch (status) {
      case 'PAID':
        return (label: 'ชำระเงินสำเร็จ', color: AppColors.semanticSuccessBorderHigh);
      case 'FAILED':
        return (label: 'ชำระเงินไม่สำเร็จ', color: AppColors.semanticErrorBgHigh);
      case 'EXPIRED':
        return (label: 'QR หมดอายุแล้ว', color: AppColors.semanticErrorBgHigh);
      case 'REFUNDED':
        return (label: 'คืนเงินแล้ว', color: AppColors.foundationAlphaWhite400);
      case 'AWAITING_PAYMENT':
      default:
        return (label: 'รอชำระเงิน', color: AppColors.semanticWarningBorderHigh);
    }
  }

  String _formatCountdown(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Widget _buildQRScreen(Map<String, dynamic> result) {
    if (_intentStatus == 'PAID') return _buildSuccessScreen();

    final intentId = result['intent_id']?.toString() ?? '';
    final qrCodeUrl = result['qr_code_url']?.toString() ?? '';
    final display = _statusDisplay(_intentStatus);
    final canRetry = _intentStatus == 'EXPIRED' || _intentStatus == 'FAILED';

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
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(child: QrImage(source: qrCodeUrl)),
                  ),
                  // Dim the QR once it can no longer be paid.
                  if (canRetry)
                    Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.error_outline,
                          size: 64, color: Colors.white),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              // Countdown until the QR expires (hidden once terminal).
              if (!_isTerminal && _expiresAt != null)
                Text(
                  'QR หมดอายุใน ${_formatCountdown(_timeLeft)}',
                  style: AppTypography.caption4.copyWith(
                    color: AppColors.foundationAlphaWhite400,
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                'หมายเลขรายการ: $intentId',
                style: AppTypography.caption5.copyWith(
                  color: AppColors.foundationAlphaWhite400,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!_isTerminal) ...[
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: display.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      display.label,
                      style: AppTypography.caption4.copyWith(color: display.color),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (canRetry)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _regenerate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.foundationOrange600,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'สร้าง QR ใหม่',
                      style: AppTypography.heading5.copyWith(color: Colors.white),
                    ),
                  ),
                ),
              if (canRetry) const SizedBox(height: 12),
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

  Widget _buildSuccessScreen() {
    return Scaffold(
      appBar: CommonAppBar(titleText: 'ชำระหนี้สำเร็จ', showLeftIcon: false),
      backgroundColor: AppColors.semanticGrayNeutralFgHigh,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Icon(Icons.check_circle,
                  size: 96, color: AppColors.semanticSuccessBorderHigh),
              const SizedBox(height: 24),
              Text(
                'ชำระหนี้ COD สำเร็จ',
                style: AppTypography.heading3.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                'ยอดหนี้ของคุณได้รับการอัปเดตแล้ว',
                textAlign: TextAlign.center,
                style: AppTypography.caption4.copyWith(
                  color: AppColors.foundationAlphaWhite400,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.foundationOrange600,
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
