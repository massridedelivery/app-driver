import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:massdrive/common/widgets/qr_image.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/theme/app_palette.dart';
import 'package:massdrive/core/constants/app_routes.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/services/socket_service.dart';
import 'package:massdrive/features/dependency_injection.dart';
import 'package:massdrive/features/home/presentation/screens/home_screen.dart';
import 'package:massdrive/features/incoming_job/presentation/controllers/incoming_job_controller.dart';
import 'package:massdrive/features/job_live/domain/repositories/job_live_repository.dart';
import 'package:massdrive/features/messenger/domain/repositories/messenger_repository.dart';
import 'package:massdrive/features/payment/data/payment_api_service.dart';
import 'package:massdrive/features/review/data/customer_review_api.dart';

enum PaymentMethod { cash, qr }

class PaymentScreen extends ConsumerStatefulWidget {
  final String passengerName;
  final double baseFare;

  /// Explicit collect amount/method/title for verticals that don't use the
  /// ride IncomingJobController (e.g. messenger passes its order `fare`).
  final double? amount;
  final String? methodLabel;
  final String? title;

  /// Messenger payer model (dev14). [codAmount] is the goods value collected
  /// from the recipient — a SEPARATE debt from the delivery fee ([amount]),
  /// shown on its own line, never summed. [payer]/[collectAt] describe who pays
  /// and where. [paymentStatus] == 'PAID' means the fee was prepaid (sender QR),
  /// so there is nothing to collect here.
  final double? codAmount;
  final String? payer;
  final String? collectAt;
  final String? paymentStatus;

  /// Mid-trip collection (messenger PICKUP stage): collect the fee, then return
  /// to the live screen (pop true) so the trip continues — instead of the
  /// terminal complete-job + review + home flow. The caller advances the stage.
  final bool midTrip;

  /// Review context for verticals whose job isn't in the ride controller
  /// (messenger passes its order id + service so the post-payment review can
  /// attach to the right order).
  final String? orderId;
  final ReviewService? service;

  /// New payment flow (SCRUM-86): collection gates completion — the job is
  /// marked COMPLETED/delivered only after payment is settled here. When false
  /// (legacy/food), the caller already completed and this screen just collects.
  final bool gateCompletion;

  const PaymentScreen({
    super.key,
    this.passengerName = 'ลูกค้า',
    this.baseFare = 0.0,
    this.amount,
    this.methodLabel,
    this.title,
    this.codAmount,
    this.payer,
    this.collectAt,
    this.paymentStatus,
    this.midTrip = false,
    this.orderId,
    this.service,
    this.gateCompletion = false,
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

  double get _baseFare {
    final job = ref.read(incomingJobControllerProvider).currentJob;
    // Prefer amount_due (fare + en-route tolls/waiting) when the BE actually
    // ships a real value; dev BE currently sends 0/null, so fall back to the
    // fare — never collect ฿0 (SCRUM-86 §6).
    for (final v in [widget.amount, job?.amountDue, job?.netIncome, widget.baseFare]) {
      if (v != null && v > 0) return v;
    }
    return 0;
  }

  // The customer pays the job fare (already net of any discount) plus any
  // real add-ons the driver enters (tolls / others). No app fee is added on
  // top of the customer's bill — platform commission is deducted separately.
  double get _totalFare => _baseFare + _tolls + _others;

  // ── QR collection (SCRUM-86) ───────────────────────────────────────────────
  static const _pollInterval = Duration(seconds: 3);
  Timer? _pollTimer;
  StreamSubscription? _wsSub;
  bool _loadingQr = false;
  bool _submitting = false;
  String? _intentId;
  String? _qrCodeUrl;
  String _status = 'AWAITING_PAYMENT';
  String? _overrideReason;
  // Hidden for now (per product): the "ลูกค้าจ่ายแล้วแต่ระบบยังไม่ขึ้น?" manual
  // override entry point. Flip to true to re-expose it. The override logic
  // itself is intact — only the UI affordance is gated.
  final bool _showManualOverride = false;

  bool get _paid => _status == 'PAID';
  // Fee already settled before this screen (sender prepaid by QR, dev14) — no
  // collection to do, just confirm the delivery.
  bool get _alreadyPaid =>
      (widget.paymentStatus ?? '').toUpperCase() == 'PAID';
  bool get _isMessenger => widget.service == ReviewService.messenger;
  double get _codAmount => widget.codAmount ?? 0.0;

  /// Messenger context line: who to collect from + at which stage (dev14).
  String? get _collectContext {
    final who = switch (widget.payer?.toUpperCase()) {
      'RECIPIENT' => 'ผู้รับ',
      'SENDER' => 'ผู้ส่ง',
      _ => null,
    };
    final where = switch (widget.collectAt?.toUpperCase()) {
      'PICKUP' => 'จุดรับ',
      'DELIVERY' => 'จุดส่ง',
      _ => null,
    };
    if (who == null && where == null) return null;
    if (who != null && where != null) return 'เก็บจาก$who ที่$where';
    return 'เก็บจาก${who ?? where}';
  }
  String get _orderId =>
      widget.orderId ??
      ref.read(incomingJobControllerProvider).currentJob?.jobId ??
      '';

  @override
  void initState() {
    super.initState();
    // Resolve the method from the passed label OR the ride/food job (ride and
    // food push /payment without a methodLabel, so fall back to the job's).
    final job = ref.read(incomingJobControllerProvider).currentJob;
    final label =
        (widget.methodLabel ?? job?.paymentMethod ?? '').toLowerCase();
    final isQr = label.contains('qr') || label.contains('promptpay');
    final isFood = job?.isFood ?? (widget.service == ReviewService.food);
    // Fee already prepaid (sender QR, dev14): nothing to collect — reflect PAID
    // so completion is ungated and skip the intent/poll entirely.
    if (_alreadyPaid) {
      _status = 'PAID';
      return;
    }
    // Food's payment-intent endpoint isn't defined yet (BE) — keep the static
    // QR for food; only ride/messenger fetch a live intent + poll.
    if (isQr && !isFood) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startQrFlow());
    }
  }

  Future<void> _startQrFlow() async {
    if (_intentId != null) return; // already started
    setState(() => _loadingQr = true);
    Map<String, dynamic> intent = {};
    try {
      final res = await ref.read(paymentApiServiceProvider).createIntent(
            orderId: _orderId,
            messenger: _isMessenger,
          );
      if (res.isSuccessful && res.data is Map) {
        intent = Map<String, dynamic>.from(res.data as Map);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('PaymentScreen.createIntent: $e');
    }
    if (!mounted) return;
    setState(() {
      _intentId = intent['intent_id']?.toString();
      _qrCodeUrl = intent['qr_code_url']?.toString();
      _status = intent['status']?.toString() ?? 'AWAITING_PAYMENT';
      _loadingQr = false;
    });
    if (_paid) return;
    // Primary: payment_paid WS event. Fallback: poll.
    _wsSub = ref.read(socketServiceProvider).messages.listen((msg) {
      if (msg.type != 'payment_paid') return;
      final data = msg.data ?? msg.raw;
      final id = data['intent_id']?.toString();
      if ((id == null || id == _intentId) &&
          data['status']?.toString() == 'PAID') {
        _markPaid();
      }
    });
    _pollTimer = Timer.periodic(_pollInterval, (_) => _pollStatus());
  }

  Future<void> _pollStatus() async {
    final id = _intentId;
    if (id == null || _paid) return;
    try {
      final res = await ref.read(paymentApiServiceProvider).getIntent(id);
      final status = (res.data is Map) ? res.data['status']?.toString() : null;
      if (status == 'PAID') {
        _markPaid();
      } else if (status == 'EXPIRED' || status == 'FAILED') {
        // QR expired/failed (10-min TTL) — stop polling and let the driver
        // request a fresh QR (or switch to cash). The order is NOT cancelled.
        _pollTimer?.cancel();
        if (mounted) setState(() => _status = status!);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('PaymentScreen.poll: $e');
    }
  }

  bool get _expired => _status == 'EXPIRED' || _status == 'FAILED';

  /// Request a fresh QR after the previous one expired (BE keeps the order).
  Future<void> _requestNewQr() async {
    _pollTimer?.cancel();
    _wsSub?.cancel();
    setState(() {
      _intentId = null;
      _qrCodeUrl = null;
      _status = 'AWAITING_PAYMENT';
    });
    await _startQrFlow();
  }

  void _markPaid() {
    if (_paid || !mounted) return;
    _pollTimer?.cancel();
    _wsSub?.cancel();
    setState(() => _status = 'PAID');
    // Auto-finish once paid — the driver shouldn't have to tap a second time.
    // Briefly show the "ชำระเงินแล้ว ✓" state, then advance the flow itself.
    // Only for the collect-first gate (or a mid-trip collection); legacy
    // non-gated callers keep their manual confirm.
    if (widget.gateCompletion || widget.midTrip) {
      Future.delayed(const Duration(milliseconds: 900), () {
        if (!mounted || _status != 'PAID' || _submitting) return;
        _onConfirmPayment();
      });
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _wsSub?.cancel();
    _tollController.dispose();
    _othersController.dispose();
    super.dispose();
  }

  /// The confirm gate applies only to the new collect-first flow
  /// ([gateCompletion]). There, a QR job may be confirmed only once PAID (or a
  /// manual override is filed); cash settles on confirm. Legacy/food (already
  /// completed by the caller) is never gated.
  bool get _canConfirm =>
      !widget.gateCompletion ||
      _currentMethod == PaymentMethod.cash ||
      _paid ||
      _overrideReason != null;

  /// Send the completion the collection was gating (SCRUM-86). Only when
  /// [PaymentScreen.gateCompletion] — otherwise the caller already completed.
  Future<bool> _completeJob() async {
    if (!widget.gateCompletion) return true;
    try {
      if (_isMessenger) {
        await getIt<MessengerRepository>().deliveredOrder(
          _orderId,
          paymentOverrideReason: _overrideReason,
        );
      } else {
        await getIt<JobLiveRepository>().updateJobStatus(_orderId, {
          'status': 'COMPLETED',
          if (_overrideReason != null) 'payment_override_reason': _overrideReason,
        });
      }
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('PaymentScreen.complete: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('จบงานไม่สำเร็จ กรุณาลองใหม่')),
        );
      }
      return false;
    }
  }

  Future<void> _showOverrideDialog() async {
    final ctrl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dctx) => AlertDialog(
        backgroundColor: dctx.palette.surface,
        title: Text('ลูกค้าจ่ายแล้วแต่ระบบยังไม่ขึ้น?',
            style: AppTypography.heading5
                .copyWith(color: dctx.palette.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ระบุเหตุผล (เช่น ลูกค้าโชว์สลิปแล้ว) — งานจะจบได้ทันที '
              'แต่ค่างานจะยังไม่เข้า จนกว่าฝ่ายการเงินจะตรวจสอบและอนุมัติ',
              style: AppTypography.caption4
                  .copyWith(color: dctx.palette.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              minLines: 1,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'เหตุผล'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dctx),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dctx, ctrl.text.trim()),
            child: const Text('ยืนยัน'),
          ),
        ],
      ),
    );
    if (reason != null && reason.isNotEmpty && mounted) {
      setState(() => _overrideReason = reason);
    }
  }

  Future<void> _onConfirmPayment() async {
    if (_submitting || !_canConfirm) return;
    setState(() => _submitting = true);

    // Messenger cash needs an explicit collect-cash call (settlement); ride
    // cash settles via the complete-job call below.
    if (_currentMethod == PaymentMethod.cash &&
        _isMessenger &&
        _overrideReason == null) {
      try {
        final res = await ref
            .read(paymentApiServiceProvider)
            .collectCash(orderId: _orderId);
        if (!res.isSuccessful) throw Exception('collect-cash failed');
      } catch (e) {
        if (kDebugMode) debugPrint('PaymentScreen.collectCash: $e');
        if (mounted) {
          setState(() => _submitting = false);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('ยืนยันเงินสดไม่สำเร็จ กรุณาลองใหม่')));
        }
        return;
      }
    }

    // Mid-trip (messenger PICKUP): payment settled → hand back to the live
    // screen, which advances the stage. Don't complete the job or run the
    // terminal review/home flow.
    if (widget.midTrip) {
      if (mounted) Navigator.of(context).pop(true);
      return;
    }

    // Gate: complete the job only once payment is settled (or overridden).
    if (!await _completeJob()) {
      if (mounted) setState(() => _submitting = false);
      return;
    }
    if (!mounted) return;

    // Capture the review context BEFORE clearing the job state below.
    final job = ref.read(incomingJobControllerProvider).currentJob;
    final reviewId = job?.jobId ?? widget.orderId;
    final reviewService =
        widget.service ??
        ((job?.isFood ?? false) ? ReviewService.food : ReviewService.ride);
    final customerName =
        widget.title ?? job?.passengerName ?? widget.passengerName;

    // 1. Dismiss modal and clear current job state (IncomingJobController)
    ref.read(incomingJobControllerProvider.notifier).dismissModal();

    // 2. Explicitly disconnect socket to ensure a fresh session for the next job
    ref.read(socketServiceProvider).disconnect();

    // 3. Refresh online status on backend (Ensures status BUSY -> ONLINE)
    // setStatus(true, force: true) will automatically call connect() and start location updates
    ref.read(onlineStatusProvider.notifier).setStatus(true, force: true);

    if (!mounted) return;

    // 4. Ask the driver to rate the customer, then home. With no job id to
    // attach the review to, go straight home. ('/' matches no route and only
    // looks right because errorBuilder renders HomeScreen.)
    if (reviewId != null && reviewId.isNotEmpty) {
      context.go(
        '/review-customer',
        extra: {
          'jobId': reviewId,
          'service': reviewService,
          'customerName': customerName,
        },
      );
    } else {
      context.go(AppRoutes.homeNamedPage);
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
                  // Tell the driver who to collect from and at which stage
                  // (messenger PICKUP/DELIVERY) — dev14.
                  if (_collectContext != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _collectContext!,
                        style: AppTypography.body2.copyWith(color: Colors.white),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Bottom Sheet Content
          Expanded(
            flex: 6,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: context.palette.sheet, // themeable panel
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
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.viewPaddingOf(context).bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.palette.border,
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
          _buildBreakdownRow(_isMessenger ? "ค่าส่ง" : "ค่าโดยสาร", _baseFare),
          const SizedBox(height: 16),
          if (_tolls > 0) ...[
            _buildBreakdownRow("ค่าทางด่วน", _tolls),
            const SizedBox(height: 16),
          ],
          if (_others > 0) ...[
            _buildBreakdownRow("อื่นๆ", _others),
            const SizedBox(height: 16),
          ],
          // COD goods value (dev14): a SEPARATE debt from the delivery fee —
          // its own line, never folded into the fee total above.
          if (_codAmount > 0) ...[
            _buildBreakdownRow("ค่าสินค้า (เก็บปลายทาง)", _codAmount),
            const SizedBox(height: 16),
          ],

          // _buildInputRow(
          //   "ค่าทางด่วน",
          //   "โปรดตรวจสอบความถูกต้องของจำนวนเงิน",
          //   _tollController,
          // ),
          // const SizedBox(height: 16),
          // _buildInputRow("อื่นๆ", null, _othersController),
          Divider(color: context.palette.border, height: 40),

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    "ทั้งหมด",
                    style: AppTypography.heading5.copyWith(color: context.palette.textPrimary),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: context.palette.surfaceAlt,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      "เงินสด",
                      style: AppTypography.caption4.copyWith(
                        color: context.palette.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                "฿${_totalFare.toStringAsFixed(0)}",
                style: AppTypography.heading5.copyWith(color: context.palette.textPrimary),
              ),
            ],
          ),
          // When there is COD, the driver physically collects fee + goods value —
          // show the combined cash figure without conflating the two line items.
          if (_codAmount > 0) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "รวมเก็บเงินสด",
                  style: AppTypography.body2.copyWith(
                    color: context.palette.textSecondary,
                  ),
                ),
                Text(
                  "฿${(_totalFare + _codAmount).toStringAsFixed(0)}",
                  style: AppTypography.body2.copyWith(
                    color: context.palette.textSecondary,
                  ),
                ),
              ],
            ),
          ],

          const Spacer(),

          // Confirm Button — cash settles on confirm.
          _buildConfirmButton(label: 'รับเงินสดแล้ว'),
        ],
      ),
    );
  }

  Widget _buildQRContent() {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    // Scrollable so the bottom affordances (change-to-cash, etc.) are always
    // reachable on short screens; ConstrainedBox + IntrinsicHeight keep the
    // confirm button pinned near the bottom when there IS spare room.
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: (constraints.maxHeight - 48 - bottomInset)
                  .clamp(0.0, double.infinity),
            ),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  // Drag handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.palette.border,
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
                  "ชำระผ่าน QR พร้อมเพย์",
                  style: AppTypography.heading5.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Live Omise QR (SCRUM-86) — fetched from the payment intent.
          Container(
            width: 200,
            height: 200,
            color: Colors.white,
            alignment: Alignment.center,
            child: _loadingQr
                ? const CircularProgressIndicator(strokeWidth: 2)
                : _expired
                    ? const Icon(Icons.timer_off_outlined,
                        size: 72, color: Colors.black38)
                    : QrImage(source: _qrCodeUrl ?? ''),
          ),

          const SizedBox(height: 20),
          if (_paid)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle,
                    color: AppColors.semanticSuccessBorderHigh, size: 20),
                const SizedBox(width: 6),
                Text(
                  "ชำระเงินแล้ว",
                  style: AppTypography.body1
                      .copyWith(color: AppColors.semanticSuccessBorderHigh),
                ),
              ],
            )
          else if (_expired) ...[
            Text(
              "QR หมดอายุแล้ว",
              style: AppTypography.body1
                  .copyWith(color: AppColors.semanticErrorBgHigh),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _requestNewQr,
              child: Text(
                "ขอ QR ใหม่",
                style: AppTypography.body1.copyWith(
                    color: Colors.blueAccent, fontWeight: FontWeight.bold),
              ),
            ),
          ] else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Text(
                  "รอลูกค้าสแกนชำระเงิน…",
                  style: AppTypography.body2
                      .copyWith(color: context.palette.textSecondary),
                ),
              ],
            ),

                  const Spacer(),

                  // Gate: only enabled once PAID (or a manual override filed).
                  _buildConfirmButton(
                    label: !widget.gateCompletion
                        ? 'ยืนยันการชำระเงิน'
                        : (_paid || _overrideReason != null
                            ? 'ยืนยันจบงาน'
                            : 'รอชำระเงิน'),
                  ),
                  const SizedBox(height: 12),
                  // Manual-override entry point — hidden for now (product).
                  if (_showManualOverride &&
                      widget.gateCompletion &&
                      !_paid)
                    TextButton(
                      onPressed: _showOverrideDialog,
                      child: Text(
                        _overrideReason != null
                            ? 'บันทึกเหตุผลแล้ว — ค่างานจะรอฝ่ายการเงินตรวจสอบ'
                            : 'ลูกค้าจ่ายแล้วแต่ระบบยังไม่ขึ้น?',
                        textAlign: TextAlign.center,
                        style: AppTypography.body2
                            .copyWith(color: Colors.blueAccent),
                      ),
                    ),
                  // Clear, tappable fallback when the QR can't be scanned.
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => setState(
                          () => _currentMethod = PaymentMethod.cash),
                      icon: const Icon(Icons.payments_outlined, size: 20),
                      label: const Text('QR ใช้ไม่ได้? เปลี่ยนไปรับเงินสดแทน'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.palette.textPrimary,
                        side: BorderSide(color: context.palette.border),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Shared confirm CTA — disabled (dimmed) until [_canConfirm], shows a spinner
  /// while submitting.
  Widget _buildConfirmButton({String label = 'ยืนยันการชำระเงิน'}) {
    final enabled = _canConfirm && !_submitting;
    return GestureDetector(
      onTap: enabled ? _onConfirmPayment : null,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: enabled
              ? AppColors.foundationGreen700
              : AppColors.foundationGreen700.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(28),
        ),
        alignment: Alignment.center,
        child: _submitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : Text(
                label,
                style: AppTypography.heading5.copyWith(color: Colors.white),
              ),
      ),
    );
  }

  Widget _buildAddButton(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: context.palette.border),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, style: AppTypography.body2.copyWith(color: context.palette.textPrimary)),
          const SizedBox(width: 4),
          Icon(Icons.add, color: context.palette.textPrimary, size: 16),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String title, double value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTypography.body1.copyWith(color: context.palette.textPrimary)),
        Text(
          value.toStringAsFixed(0),
          style: AppTypography.body1.copyWith(color: context.palette.textPrimary),
        ),
      ],
    );
  }

}
