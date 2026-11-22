import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/theme/app_palette.dart';
import 'package:massdrive/features/loans/data/loan_api.dart';
import 'package:massdrive/features/loans/domain/loan_apply_logic.dart';
import 'package:massdrive/features/loans/domain/loan_copy.dart';
import 'package:massdrive/features/loans/domain/loan_format.dart';
import 'package:massdrive/features/loans/domain/loan_models.dart';
import 'package:massdrive/features/loans/domain/loan_paths.dart';
import 'package:massdrive/features/loans/presentation/loan_providers.dart';
import 'package:massdrive/features/loans/presentation/widgets/loan_ui.dart';

final _withdrawableProvider = FutureProvider.autoDispose<double?>(
  (ref) => ref.read(loanApiProvider).withdrawable(),
  retry: (_, _) => null,
);

enum _Choice { arrears, part, payoff }

/// Screen 13 (design 13A): pick what to do (arrears / part / everything),
/// then the amount, then `POST /loans/:id/repay` (amount 0 = pay off).
class LoanPayScreen extends ConsumerStatefulWidget {
  const LoanPayScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<LoanPayScreen> createState() => _LoanPayScreenState();
}

class _LoanPayScreenState extends ConsumerState<LoanPayScreen> {
  _Choice? _choice;
  bool _amountStep = false;
  final _amount = TextEditingController();
  bool _sending = false;
  String? _error;
  double? _suggest;
  ({double paid, Loan after, DateTime at})? _success;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  double? get _typed {
    final v = double.tryParse(_amount.text.replaceAll(',', ''));
    return v == null || v <= 0 ? null : (v * 100).round() / 100;
  }

  Future<void> _pay(Loan l, {required bool payoff, double? amount}) async {
    final sentAt = DateTime.now();
    final paid = payoff ? l.payoffAmount : amount!;
    setState(() {
      _sending = true;
      _error = null;
      _suggest = null;
    });
    try {
      final after = await ref
          .read(loanApiProvider)
          .repay(l.id, payoff ? 0 : amount!);
      _paid(paid, after);
    } on LoanApiException catch (e) {
      if (!mounted) return;
      switch (repayErrorAction(e)) {
        case RepayErrorAction.leave:
          LoanAvailability.instance.report(e);
          leaveLoans(context);
        case RepayErrorAction.insufficient:
          final w = e.withdrawable;
          setState(() {
            _error = w == null
                ? 'ยอดที่ถอนได้ในกระเป๋าไม่พอ'
                : 'ยอดที่ถอนได้ในกระเป๋าไม่พอ (มี ${baht2(w)})';
            _suggest = w != null && w > 0 ? w : null;
          });
          ref.invalidate(_withdrawableProvider);
        case RepayErrorAction.refresh:
          setState(
            () => _error =
                'ข้อมูลสินเชื่อมีการเปลี่ยนแปลง โหลดใหม่แล้ว กรุณาตรวจสอบอีกครั้ง',
          );
          ref.invalidate(loanDetailProvider(l.id));
        case RepayErrorAction.check:
          await _check(l, paid, sentAt);
        case RepayErrorAction.failed:
          setState(() => _error = 'ชำระไม่สำเร็จ กรุณาลองอีกครั้ง');
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  /// No answer: look for the payment before offering a retry.
  Future<void> _check(Loan l, double paid, DateTime sentAt) async {
    setState(() => _error = 'ยังไม่แน่ใจว่าชำระสำเร็จหรือไม่ กำลังตรวจสอบ…');
    try {
      final d = await ref.read(loanApiProvider).loan(l.id);
      final landed = d.events.any(
        (e) =>
            e.type == LoanEventType.manualPayment &&
            e.createdAt != null &&
            e.createdAt!.isAfter(sentAt.subtract(const Duration(minutes: 1))),
      );
      if (!mounted) return;
      if (landed) {
        _paid(paid, d.loan);
      } else {
        setState(
          () => _error = 'ชำระไม่สำเร็จ ยังไม่มีการตัดเงิน กรุณาลองอีกครั้ง',
        );
      }
    } on LoanApiException {
      if (mounted) {
        setState(
          () => _error = 'ยังตรวจสอบไม่ได้ กรุณาลองอีกครั้งภายหลัง ก่อนชำระซ้ำ',
        );
      }
    }
  }

  void _paid(double paid, Loan after) {
    if (!mounted) return;
    LoanUpdates.instance.notifyChanged();
    if (after.status == LoanStatus.paidOff) {
      context.pushReplacement(LoanPaths.loan(after.id));
      return;
    }
    setState(() => _success = (paid: paid, after: after, at: DateTime.now()));
  }

  @override
  Widget build(BuildContext context) {
    final v = ref.watch(loanDetailProvider(widget.id));
    final w = ref.watch(_withdrawableProvider).asData?.value;
    final l = v.asData?.value.loan;
    return PopScope(
      canPop: !_sending && (!_amountStep || _success != null),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _amountStep && !_sending) {
          setState(() => _amountStep = false);
        }
      },
      child: LoanPage(
        title: 'จ่ายเงินสินเชื่อ',
        footer: l == null || _success != null ? null : _footer(l, w),
        body: LoanAsync<LoanDetail>(
          value: v,
          errorTitle: 'โหลดยอดไม่สำเร็จ',
          onRetry: () => ref.invalidate(loanDetailProvider(widget.id)),
          builder: (d) {
            if (_success != null) return _successBody();
            if (!d.loan.acceptsPayments) {
              return LoanMessage(
                symbol: 'ⓘ',
                title: 'สินเชื่อนี้ปิดยอดแล้ว',
                actionLabel: 'ไปหน้าสินเชื่อ',
                onAction: () =>
                    context.pushReplacement(LoanPaths.loan(d.loan.id)),
              );
            }
            return _amountStep
                ? _amountBody(d.loan, w)
                : _choiceBody(d.loan, w);
          },
        ),
      ),
    );
  }

  Widget? _footer(Loan l, double? wallet) {
    if (!l.acceptsPayments) return null;
    if (!_amountStep) {
      return LoanFooterButtons(
        note: 'จ่ายก่อนกำหนดได้ ไม่มีค่าปรับ',
        secondary: 'ยกเลิก',
        onSecondary: () => Navigator.of(context).maybePop(),
        primary: 'ถัดไป',
        onPrimary:
            _choice == null ||
                (_choice == _Choice.payoff && _payoffShort(l, wallet) > 0)
            ? null
            : () {
                setState(() {
                  _amountStep = true;
                  _error = null;
                  _suggest = null;
                  if (_choice == _Choice.arrears) {
                    _amount.text = l.arrears.toStringAsFixed(2);
                  }
                });
              },
      );
    }
    final payoff = _choice == _Choice.payoff;
    final amount = payoff ? l.payoffAmount : _typed;
    final valid = payoff || (amount != null && amount <= l.balance);
    return LoanFooterButtons(
      secondary: 'กลับ',
      onSecondary: () => setState(() => _amountStep = false),
      primary: amount == null ? 'ชำระ' : 'ชำระ ${baht2(amount)}',
      loading: _sending,
      onPrimary: valid ? () => _pay(l, payoff: payoff, amount: amount) : null,
    );
  }

  /// How much the wallet lacks for paying off; 0 when enough or unknown.
  double _payoffShort(Loan l, double? wallet) =>
      wallet == null || wallet >= l.payoffAmount
      ? 0
      : ((l.payoffAmount - wallet) * 100).round() / 100;

  Widget _choiceBody(Loan l, double? wallet) {
    final p = context.palette;
    final short = _payoffShort(l, wallet);
    final payoffCard = _card(
      _Choice.payoff,
      title: 'ปิดยอดทั้งหมด ${baht2(l.payoffAmount)}',
      lines: [
        if (l.interestFreePayoff && l.coolingOffUntil != null) ...[
          '★ ${coolingOffLine(l.disclosure.coolingOffDays)}',
          coolingOffUntilText(l.coolingOffUntil!),
        ],
        if (short > 0) '⚠ ยอดในกระเป๋าไม่พอ ขาด ${baht2(short)}',
      ],
      enabled: short <= 0,
    );
    final cards = <Widget>[
      if (l.arrears > 0)
        _card(
          _Choice.arrears,
          title: 'จ่ายยอดค้าง ${baht2(l.arrears)}',
          lines: [if (l.daysBehind > 0) 'ค้าง ${l.daysBehind} วัน'],
        ),
      if (l.interestFreePayoff) payoffCard,
      _card(
        _Choice.part,
        title: 'จ่ายบางส่วน',
        lines: const ['เลือกจำนวนเอง ลดยอดคงเหลือ'],
      ),
      if (!l.interestFreePayoff) payoffCard,
    ];
    return LoanList(
      children: [
        Text(
          'ยอดคงเหลือ ${baht2(l.balance)}',
          style: AppTypography.heading5.copyWith(color: p.textPrimary),
        ),
        if (wallet != null)
          Text(
            'กระเป๋าเงิน (ถอนได้) ${baht2(wallet)}',
            style: AppTypography.caption4.copyWith(color: p.textSecondary),
          ),
        const SizedBox(height: 12),
        for (final c in cards) ...[c, const SizedBox(height: 10)],
      ],
    );
  }

  Widget _card(
    _Choice c, {
    required String title,
    List<String> lines = const [],
    bool enabled = true,
  }) {
    final p = context.palette;
    final selected = _choice == c;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => setState(() => _choice = c),
      child: LoanCard(
        borderColor: selected ? loanGreen : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              selected ? '●' : '○',
              style: AppTypography.caption2.copyWith(
                color: selected ? loanGreen : p.textSecondary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.caption3.copyWith(
                      color: enabled ? p.textPrimary : p.textTertiary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  for (final l in lines)
                    Text(
                      l,
                      style: AppTypography.caption5.copyWith(
                        color: p.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _amountBody(Loan l, double? wallet) {
    final p = context.palette;
    final payoff = _choice == _Choice.payoff;
    final amount = payoff ? l.payoffAmount : _typed;
    final preview = amount == null || payoff ? null : repayPreview(l, amount);
    return LoanList(
      children: [
        if (payoff) ...[
          Text(
            'ปิดยอดทั้งหมด',
            style: AppTypography.heading5.copyWith(color: p.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'ระบบจะปิดยอดตามยอดจริงตอนชำระ (ตอนนี้ ${baht2(l.payoffAmount)}) หักจากกระเป๋าเงิน',
            style: AppTypography.caption4.copyWith(color: p.textPrimary),
          ),
          if (l.interestFreePayoff && l.coolingOffUntil != null)
            LoanBanner(
              symbol: '★',
              title: coolingOffLine(l.disclosure.coolingOffDays),
              lines: [coolingOffUntilText(l.coolingOffUntil!)],
              tone: LoanTone.success,
            ),
        ] else ...[
          Text(
            'จำนวนที่จะจ่าย',
            style: AppTypography.caption3.copyWith(
              color: p.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _amount,
            enabled: !_sending,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            style: AppTypography.heading4.copyWith(color: p.textPrimary),
            decoration: InputDecoration(
              prefixText: '฿  ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          Wrap(
            spacing: 4,
            children: [
              TextButton(
                onPressed: _sending
                    ? null
                    : () => setState(
                        () =>
                            _amount.text = l.dailyInstalment.toStringAsFixed(2),
                      ),
                child: Text('1 งวด ${baht2(l.dailyInstalment)}'),
              ),
              if (wallet != null && wallet > 0)
                TextButton(
                  onPressed: _sending
                      ? null
                      : () => setState(
                          () => _amount.text =
                              (wallet < l.balance ? wallet : l.balance)
                                  .toStringAsFixed(2),
                        ),
                  child: const Text('ทั้งหมดที่ถอนได้'),
                ),
            ],
          ),
          if (amount != null && amount > l.balance)
            Text(
              'จ่ายได้ไม่เกินยอดคงเหลือ ${baht2(l.balance)}',
              style: AppTypography.caption4.copyWith(color: loanWarning),
            ),
          if (preview != null && amount! <= l.balance) ...[
            const SizedBox(height: 6),
            Text(
              'ดอกเบี้ย ${baht2(preview.interest)} → เงินต้น ${baht2(preview.principal)} (โดยประมาณ)',
              style: AppTypography.caption4.copyWith(color: p.textSecondary),
            ),
            Text(
              'ยอดคงเหลือหลังจ่าย ${baht2(preview.balanceAfter)} (โดยประมาณ)',
              style: AppTypography.caption4.copyWith(color: p.textPrimary),
            ),
          ],
        ],
        if (_error != null) ...[
          const SizedBox(height: 10),
          LoanBanner(
            symbol: '⚠',
            title: _error!,
            tone: LoanTone.warning,
            actions: [
              if (_suggest != null)
                TextButton(
                  onPressed: () => setState(() {
                    _choice = _Choice.part;
                    _amount.text = _suggest!.toStringAsFixed(2);
                    _error = null;
                    _suggest = null;
                  }),
                  child: Text('จ่าย ${baht2(_suggest!)} แทน'),
                ),
              TextButton(
                onPressed: () => setState(() => _error = null),
                child: const Text('ยกเลิก'),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _successBody() {
    final p = context.palette;
    final s = _success!;
    return LoanList(
      children: [
        const SizedBox(height: 16),
        Text(
          '✓ ชำระแล้ว ${baht2(s.paid)}',
          style: AppTypography.heading4.copyWith(color: loanGreen),
        ),
        const SizedBox(height: 6),
        Text(
          'ยอดคงเหลือ ${baht2(s.after.balance)}',
          style: AppTypography.caption2.copyWith(color: p.textPrimary),
        ),
        Text(
          'หักจากกระเป๋าเงิน · ${formatBangkokDateTime(s.at)}',
          style: AppTypography.caption4.copyWith(color: p.textSecondary),
        ),
        const SizedBox(height: 20),
        LoanPrimaryButton(
          'กลับหน้าสินเชื่อ',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ],
    );
  }
}
