import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:massdrive/common/widgets/appbar/base_appbar.dart';
import 'package:massdrive/common/widgets/qr_image.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/theme/app_palette.dart';

/// Who owes the money at the collection point.
enum CollectPayer { customer, sender, recipient }

/// How the money is collected on the driver app.
enum CollectMethod { cash, qr }

extension CollectPayerLabel on CollectPayer {
  String get label => switch (this) {
        CollectPayer.customer => 'ลูกค้า',
        CollectPayer.sender => 'ผู้ส่ง',
        CollectPayer.recipient => 'ผู้รับ',
      };
}

/// End-of-job **payment collection** on the driver app (SCRUM-86).
///
/// The new payment flow moves collection to the end of a job, and some payers
/// (a messenger recipient) have no customer app — so the driver collects on
/// their phone:
///  • **Cash** → confirm "received cash from {payer}" → settlement.
///  • **QR**  → show the Omise QR for the payer to scan, poll until `PAID`,
///    then the job may be completed.
///
/// The job can't be completed until [collected] is true (for cases that must be
/// paid before finishing).
///
/// While the backend (SCRUM-85) is still in flight, run with [previewMode] to
/// exercise the whole UI + poll loop against a mock intent (no BE calls).
class CollectPaymentScreen extends ConsumerStatefulWidget {
  final String orderId;
  final double amountDue;
  final CollectPayer payer;
  final CollectMethod method;

  /// Where the money is collected — shown to the driver (e.g. "จุดส่ง").
  final String collectAtLabel;

  /// Called once payment is settled (cash confirmed or QR reached `PAID`), so
  /// the caller can enable "complete job / ส่งสำเร็จ".
  final VoidCallback? onCollected;

  /// Mock the backend (no API calls): fakes a QR intent that flips to `PAID`
  /// shortly after opening, and confirms cash instantly.
  final bool previewMode;

  const CollectPaymentScreen({
    super.key,
    required this.orderId,
    required this.amountDue,
    required this.payer,
    required this.method,
    this.collectAtLabel = '',
    this.onCollected,
    this.previewMode = false,
  });

  @override
  ConsumerState<CollectPaymentScreen> createState() =>
      _CollectPaymentScreenState();
}

class _CollectPaymentScreenState extends ConsumerState<CollectPaymentScreen> {
  static const _pollInterval = Duration(seconds: 3);

  Timer? _pollTimer;
  bool _loading = false;
  bool _submitting = false;

  String? _qrCodeUrl;
  // AWAITING_PAYMENT | PAID | FAILED | EXPIRED
  String _status = 'AWAITING_PAYMENT';
  int _previewTicks = 0;

  bool get _paid => _status == 'PAID';

  @override
  void initState() {
    super.initState();
    if (widget.method == CollectMethod.qr) _startQrFlow();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  // ── QR flow ───────────────────────────────────────────────────────────────

  Future<void> _startQrFlow() async {
    setState(() => _loading = true);
    final intent = await _createIntent();
    if (!mounted) return;
    setState(() {
      _qrCodeUrl = intent['qr_code_url']?.toString();
      _status = intent['status']?.toString() ?? 'AWAITING_PAYMENT';
      _loading = false;
    });
    if (!_paid) {
      _pollTimer = Timer.periodic(_pollInterval, (_) => _pollStatus());
    }
  }

  /// Create the payment intent for this job's collection.
  /// TODO(SCRUM-86/BE): GET /api/payment/intent/order/{id} (or /job/{id}) →
  /// { qr_code_url, amount, status }. Mocked under [previewMode].
  Future<Map<String, dynamic>> _createIntent() async {
    if (widget.previewMode) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      // Empty url → QrImage shows its QR-icon fallback, enough to preview UI.
      return {'qr_code_url': '', 'status': 'AWAITING_PAYMENT'};
    }
    // Real call goes here once the BE contract is confirmed.
    return {'qr_code_url': '', 'status': 'AWAITING_PAYMENT'};
  }

  /// Poll the intent until PAID.
  /// TODO(SCRUM-86/BE): GET /api/payment/intent/{id} → { status }.
  Future<void> _pollStatus() async {
    if (_paid) {
      _pollTimer?.cancel();
      return;
    }
    if (widget.previewMode) {
      // Flip to PAID after a couple of polls so the flow can be exercised.
      if (++_previewTicks >= 2 && mounted) {
        setState(() => _status = 'PAID');
        _pollTimer?.cancel();
        widget.onCollected?.call();
      }
      return;
    }
    // Real poll goes here.
  }

  // ── Cash flow ───────────────────────────────────────────────────────────--

  /// Confirm cash was received + trigger settlement into the driver wallet.
  /// TODO(SCRUM-86/BE): POST /api/.../{id}/confirm-cash-payment.
  Future<void> _confirmCash() async {
    setState(() => _submitting = true);
    if (widget.previewMode) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    // Real confirm goes here.
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _status = 'PAID';
    });
    widget.onCollected?.call();
  }

  // ── UI ─────────────────────────────────────────────────────────────────---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.bg,
      appBar: CommonAppBar(titleText: 'เก็บเงินปลายทาง', showLeftIcon: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _paid
              ? _buildSuccess()
              : (widget.method == CollectMethod.cash
                  ? _buildCash()
                  : _buildQr()),
        ),
      ),
    );
  }

  Widget _buildAmountHeader() {
    final fmt = NumberFormat('#,##0.00');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ยอดที่ต้องเก็บ',
          style: AppTypography.caption4
              .copyWith(color: context.palette.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(
          '฿${fmt.format(widget.amountDue)}',
          style: AppTypography.heading1.copyWith(
            color: context.palette.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _chip('ผู้จ่าย: ${widget.payer.label}'),
            _chip(widget.method == CollectMethod.cash ? 'เงินสด' : 'สแกน QR'),
            if (widget.collectAtLabel.isNotEmpty)
              _chip('จุดเก็บ: ${widget.collectAtLabel}'),
          ],
        ),
      ],
    );
  }

  Widget _chip(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: context.palette.surfaceAlt,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: AppTypography.caption5
              .copyWith(color: context.palette.textSecondary),
        ),
      );

  Widget _buildCash() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAmountHeader(),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _submitting ? null : _confirmCash,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.foundationGreen600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              elevation: 0,
            ),
            child: _submitting
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    'รับเงินสดจาก${widget.payer.label}แล้ว',
                    style:
                        AppTypography.heading5.copyWith(color: Colors.white),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildQr() {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: _buildAmountHeader(),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0F3B66), // brand QR banner
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.qr_code_scanner, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'ให้${widget.payer.label}สแกนเพื่อชำระ',
                style: AppTypography.heading5.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          width: 220,
          height: 220,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: _loading
              ? const CircularProgressIndicator(strokeWidth: 2)
              : QrImage(source: _qrCodeUrl ?? ''),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Text(
              'รอการชำระเงิน…',
              style: AppTypography.caption4
                  .copyWith(color: context.palette.textSecondary),
            ),
          ],
        ),
        const Spacer(),
        // Completion is blocked until PAID — the button only lights up then.
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: null,
            style: ElevatedButton.styleFrom(
              backgroundColor: context.palette.surfaceAlt,
              disabledBackgroundColor: context.palette.surfaceAlt,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              elevation: 0,
            ),
            child: Text(
              'รอชำระเงินก่อนจบงาน',
              style: AppTypography.heading5
                  .copyWith(color: context.palette.textTertiary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    return Column(
      children: [
        const Spacer(),
        Icon(Icons.check_circle,
            size: 96, color: AppColors.semanticSuccessBorderHigh),
        const SizedBox(height: 24),
        Text(
          'รับเงินเรียบร้อย',
          style: AppTypography.heading3
              .copyWith(color: context.palette.textPrimary),
        ),
        const SizedBox(height: 8),
        Text(
          'ยอด ฿${NumberFormat('#,##0.00').format(widget.amountDue)} '
          'เข้ากระเป๋าของคุณแล้ว',
          textAlign: TextAlign.center,
          style: AppTypography.caption4
              .copyWith(color: context.palette.textSecondary),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.foundationOrange600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              elevation: 0,
            ),
            child: Text(
              widget.payer == CollectPayer.recipient ? 'กดส่งสำเร็จ' : 'จบงาน',
              style: AppTypography.heading5.copyWith(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
