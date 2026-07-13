import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/services/socket_service.dart';
import 'package:massdrive/features/home/presentation/screens/home_screen.dart';
import 'package:massdrive/features/incoming_job/presentation/controllers/incoming_job_controller.dart';

enum PaymentMethod { cash, qr }

class PaymentScreen extends ConsumerStatefulWidget {
  final String passengerName;
  final double baseFare;

  /// Explicit collect amount/method/title for verticals that don't use the
  /// ride IncomingJobController (e.g. messenger passes its order `fare`).
  final double? amount;
  final String? methodLabel;
  final String? title;

  const PaymentScreen({
    super.key,
    this.passengerName = 'Kittidet',
    this.baseFare = 0.0,
    this.amount,
    this.methodLabel,
    this.title,
  });

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  PaymentMethod? _currentMethod;

  final TextEditingController _tollController = TextEditingController();
  final TextEditingController _othersController = TextEditingController();

  double get _tolls => double.tryParse(_tollController.text) ?? 0.0;

  double get _others => double.tryParse(_othersController.text) ?? 0.0;

  double get _baseFare =>
      widget.amount ??
      ref.read(incomingJobControllerProvider).currentJob?.netIncome ??
      widget.baseFare;

  // The customer pays the job fare (already net of any discount) plus any
  // real add-ons the driver enters (tolls / others). No app fee is added on
  // top of the customer's bill — platform commission is deducted separately.
  double get _totalFare => _baseFare + _tolls + _others;

  @override
  void dispose() {
    _tollController.dispose();
    _othersController.dispose();
    super.dispose();
  }

  void _onConfirmPayment() {
    // 1. Dismiss modal and clear current job state (IncomingJobController)
    ref.read(incomingJobControllerProvider.notifier).dismissModal();

    // 2. Explicitly disconnect socket to ensure a fresh session for the next job
    ref.read(socketServiceProvider).disconnect();

    // 3. Refresh online status on backend (Ensures status BUSY -> ONLINE)
    // setStatus(true, force: true) will automatically call connect() and start location updates
    ref.read(onlineStatusProvider.notifier).setStatus(true, force: true);

    // 4. Return to home
    if (mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final jobState = ref.watch(incomingJobControllerProvider);
    final job = jobState.currentJob;
    final paymentMethodStr =
        widget.methodLabel ?? job?.paymentMethod ?? 'cash';

    _currentMethod ??=
        (paymentMethodStr.toLowerCase().contains('qr') ||
            paymentMethodStr.toLowerCase().contains('promptpay'))
        ? PaymentMethod.qr
        : PaymentMethod.cash;

    return Scaffold(
      backgroundColor: AppColors.foundationGreen900,
      // Dark green background from mockup
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          "รายการชำระเงินของ ${widget.title ?? job?.passengerName ?? widget.passengerName}",
          style: AppTypography.heading6.copyWith(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Top Price Header
          Expanded(
            flex: 2,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _totalFare.toStringAsFixed(0),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 56,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentMethod == PaymentMethod.cash
                        ? "เก็บเงินสด"
                        : "สแกนจ่าย",
                    style: AppTypography.heading6.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Sheet Content
          Expanded(
            flex: 5,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF1E1E1E), // Dark grey panel
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: _currentMethod == PaymentMethod.cash
                  ? _buildCashContent()
                  : _buildQRContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCashContent() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Buttons
          Row(
            children: [
              _buildAddButton("ค่าทางด่วน"),
              const SizedBox(width: 12),
              _buildAddButton("อื่นๆ"),
            ],
          ),
          const SizedBox(height: 24),

          // Breakdown
          _buildBreakdownRow("ค่าโดยสาร", _baseFare),
          const SizedBox(height: 16),
          if (_tolls > 0) ...[
            _buildBreakdownRow("ค่าทางด่วน", _tolls),
            const SizedBox(height: 16),
          ],
          if (_others > 0) ...[
            _buildBreakdownRow("อื่นๆ", _others),
            const SizedBox(height: 16),
          ],

          // _buildInputRow(
          //   "ค่าทางด่วน",
          //   "โปรดตรวจสอบความถูกต้องของจำนวนเงิน",
          //   _tollController,
          // ),
          // const SizedBox(height: 16),
          // _buildInputRow("อื่นๆ", null, _othersController),
          const Divider(color: Colors.white12, height: 40),

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    "ทั้งหมด",
                    style: AppTypography.heading5.copyWith(color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      "เงินสด",
                      style: AppTypography.caption4.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                "฿${_totalFare.toStringAsFixed(0)}",
                style: AppTypography.heading5.copyWith(color: Colors.white),
              ),
            ],
          ),

          const Spacer(),

          // Confirm Button
          GestureDetector(
            onTap: _onConfirmPayment,
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.foundationGreen700,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Text(
                      "ยืนยันการชำระเงิน",
                      style: AppTypography.heading5.copyWith(
                        color: AppColors.semanticGrayNeutralBgWhite,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRContent() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F3B66), // QR Banner Blue
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.qr_code_scanner, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  "THAI QR PAYMENT",
                  style: AppTypography.heading5.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // QR Image Placeholder (In real app, load network or generate bits)
          Container(
            width: 200,
            height: 200,
            color: Colors.white,
            child: const Center(
              child: Icon(Icons.qr_code, size: 100, color: Colors.black),
            ),
          ),

          const SizedBox(height: 20),
          Text(
            "Expires in 598",
            style: AppTypography.body2.copyWith(color: Colors.white70),
          ),

          const Spacer(),

          GestureDetector(
            onTap: () {
              setState(() {
                _currentMethod = PaymentMethod.cash;
              });
            },
            child: Column(
              children: [
                Text(
                  "QR ใช้ไม่ได้?",
                  style: AppTypography.body1.copyWith(color: Colors.white),
                ),
                Text(
                  "เปลี่ยนไปรับเงินสดแทน",
                  style: AppTypography.body2.copyWith(color: Colors.blueAccent),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildAddButton(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: Colors.white54),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, style: AppTypography.body2.copyWith(color: Colors.white)),
          const SizedBox(width: 4),
          const Icon(Icons.add, color: Colors.white, size: 16),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String title, double value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTypography.body1.copyWith(color: Colors.white)),
        Text(
          value.toStringAsFixed(0),
          style: AppTypography.body1.copyWith(color: Colors.white),
        ),
      ],
    );
  }

}
