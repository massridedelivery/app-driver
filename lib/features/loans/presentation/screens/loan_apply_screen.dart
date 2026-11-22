import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:massdrive/core/constants/app_routes.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/theme/app_palette.dart';
import 'package:massdrive/features/loans/data/loan_api.dart';
import 'package:massdrive/features/loans/domain/loan_apply_logic.dart';
import 'package:massdrive/features/loans/domain/loan_copy.dart';
import 'package:massdrive/features/loans/domain/loan_format.dart';
import 'package:massdrive/features/loans/domain/loan_models.dart';
import 'package:massdrive/features/loans/domain/loan_paths.dart';
import 'package:massdrive/features/loans/presentation/loan_providers.dart';
import 'package:massdrive/features/loans/presentation/screens/loan_document_reader.dart';
import 'package:massdrive/features/loans/presentation/widgets/loan_ui.dart';

enum _Step { amount, summary, documents, review }

enum _Outcome { declined, conflict, checking, notSent, checkFailed, failed }

/// Screens 3–6 as one flow, so the figures, the documents and the ticks
/// stay together: amount & term (3A) → key facts (4A) → documents (5C) →
/// review & submit (6B). Back always steps back one screen.
class LoanApplyScreen extends ConsumerStatefulWidget {
  const LoanApplyScreen({super.key});

  @override
  ConsumerState<LoanApplyScreen> createState() => _LoanApplyScreenState();
}

class _LoanApplyScreenState extends ConsumerState<LoanApplyScreen> {
  _Step _step = _Step.amount;
  final _amount = TextEditingController();
  int? _term;
  bool _customTerm = false;

  LoanQuote? _quote;
  double? _quotedPrincipal;
  int? _quotedTerm;
  DateTime? _quotedAt;
  bool _quoting = false;
  LoanApiException? _quoteError;
  int _seq = 0;
  Timer? _debounce;
  Set<String> _changed = const {};

  LoanTerms? _terms;
  (double, int)? _termsFor;
  bool _termsLoading = false;
  bool _termsError = false;
  final Set<String> _read = {};
  final Map<String, DateTime> _opened = {};
  bool _tickShared = false;
  final Map<String, bool> _tickSeparate = {};
  String? _docsNotice;
  bool _termsChanged = false;

  bool _sending = false;
  DateTime? _sentAt;
  _Outcome? _outcome;
  String? _declineReason;

  LoanApi get _api => ref.read(loanApiProvider);

  @override
  void dispose() {
    _debounce?.cancel();
    _amount.dispose();
    super.dispose();
  }

  double? get _principal {
    final digits = _amount.text.replaceAll(RegExp(r'[^0-9]'), '');
    final v = int.tryParse(digits);
    return v == null || v <= 0 ? null : v.toDouble();
  }

  bool get _quoteCurrent =>
      _quote != null &&
      !_quoting &&
      _quotedPrincipal == _principal &&
      _quotedTerm == _term;

  // ── Quote ────────────────────────────────────────────────────────────

  void _inputsChanged({bool debounce = false}) {
    _debounce?.cancel();
    final p = _principal;
    final t = _term;
    if (p != null && t != null) {
      if (debounce) {
        _debounce = Timer(
          const Duration(milliseconds: 400),
          () => _requestQuote(p, t),
        );
      } else {
        _requestQuote(p, t);
      }
    }
    setState(() {});
  }

  Future<void> _requestQuote(double p, int t, {bool compare = false}) async {
    final seq = ++_seq;
    final old = _quote;
    setState(() {
      _quoting = true;
      _quoteError = null;
    });
    try {
      final q = await _api.quote(p, t);
      if (!mounted || seq != _seq) return;
      setState(() {
        _quote = q;
        _quotedPrincipal = p;
        _quotedTerm = t;
        _quotedAt = DateTime.now();
        _quoting = false;
        _changed = compare && old != null ? changedCostLines(old, q) : const {};
        if (isQuoteDeclined(q)) {
          _outcome = _Outcome.declined;
          _declineReason = q.declineReason;
        }
      });
    } on LoanApiException catch (e) {
      if (!mounted || seq != _seq) return;
      if (e.lendingOff) {
        LoanAvailability.instance.report(e);
        leaveLoans(context);
        return;
      }
      setState(() {
        _quoting = false;
        _quoteError = e;
      });
    }
  }

  void _setPrincipal(double v) {
    _amount.text = NumberFormat('#,##0').format(v.round());
    _inputsChanged();
  }

  void _setTerm(int t, {bool custom = false}) {
    _term = t;
    _customTerm = custom;
    _inputsChanged();
  }

  // ── Documents ────────────────────────────────────────────────────────

  void _resetConsents() {
    _read.clear();
    _opened.clear();
    _tickShared = false;
    _tickSeparate.clear();
  }

  Future<void> _loadTerms({
    bool changedOnServer = false,
    String? notice,
  }) async {
    final p = _principal!;
    final t = _term!;
    setState(() {
      _termsLoading = true;
      _termsError = false;
    });
    try {
      final terms = await _api.terms(p, t);
      if (!mounted) return;
      setState(() {
        _termsLoading = false;
        if (!terms.isWellFormed) {
          _termsError = true;
          return;
        }
        _terms = terms;
        _termsFor = (p, t);
        _resetConsents();
        _termsChanged = changedOnServer;
        _docsNotice = notice;
      });
    } on LoanApiException catch (e) {
      if (!mounted) return;
      if (e.lendingOff) {
        LoanAvailability.instance.report(e);
        leaveLoans(context);
        return;
      }
      setState(() {
        _termsLoading = false;
        _termsError = true;
      });
    }
  }

  void _goDocuments() {
    setState(() => _step = _Step.documents);
    final figures = (_principal!, _term!);
    if (_terms == null || _termsFor != figures) {
      _loadTerms(
        notice: _terms != null
            ? 'เปลี่ยนยอดแล้ว ต้องยอมรับเอกสารอีกครั้ง'
            : null,
      );
    }
  }

  void _openDoc(int i) {
    final terms = _terms!;
    LoanDocumentReader.open(
      context,
      documents: terms.documents,
      index: i,
      version: terms.version,
      read: {..._read},
      onOpened: (kind) => _opened.putIfAbsent(kind, () => DateTime.now()),
      onRead: (kind) {
        if (mounted) setState(() => _read.add(kind));
      },
    );
  }

  bool get _allTicked =>
      _terms != null &&
      _tickShared &&
      _terms!.separate.every((d) => _tickSeparate[d.kind] == true);

  // ── Submit ───────────────────────────────────────────────────────────

  Future<void> _send() async {
    final p = _principal!;
    final t = _term!;
    final terms = _terms!;
    final sentAt = DateTime.now();
    _sentAt = sentAt;
    setState(() {
      _sending = true;
      _outcome = null;
    });
    try {
      final app = await _api.apply(
        principal: p,
        termDays: t,
        terms: terms,
        documentsOpened: Map.of(_opened),
      );
      _done(app);
    } on LoanApiException catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      switch (applyErrorAction(e)) {
        case ApplyErrorAction.leave:
          LoanAvailability.instance.report(e);
          leaveLoans(context);
        case ApplyErrorAction.termsOutdated:
          setState(() => _step = _Step.documents);
          await _loadTerms(changedOnServer: true);
        case ApplyErrorAction.consentMissing:
          setState(() {
            _step = _Step.documents;
            _docsNotice = 'กรุณาติ๊กยอมรับทั้งสองข้อก่อนส่งคำขอ';
          });
        case ApplyErrorAction.conflict:
          setState(() => _outcome = _Outcome.conflict);
        case ApplyErrorAction.declined:
          setState(() {
            _outcome = _Outcome.declined;
            _declineReason = e.declineReason;
          });
        case ApplyErrorAction.fixFigures:
          setState(() => _step = _Step.amount);
          _requestQuote(p, t);
        case ApplyErrorAction.check:
          await _check(p, t, sentAt);
        case ApplyErrorAction.failed:
          setState(() => _outcome = _Outcome.failed);
      }
    }
  }

  /// The send may have landed: look before offering to send again.
  Future<void> _check(double p, int t, DateTime sentAt) async {
    setState(() => _outcome = _Outcome.checking);
    try {
      final apps = await _api.applications();
      final match = findSubmittedApplication(
        apps,
        principal: p,
        termDays: t,
        sentAt: sentAt,
      );
      if (!mounted) return;
      if (match != null) {
        _done(match);
      } else {
        setState(() => _outcome = _Outcome.notSent);
      }
    } on LoanApiException {
      if (mounted) setState(() => _outcome = _Outcome.checkFailed);
    }
  }

  void _done(LoanApplication app) {
    if (!mounted) return;
    LoanUpdates.instance.notifyChanged();
    showLoanSnack(context, 'ส่งคำขอแล้ว รอเจ้าหน้าที่อนุมัติ');
    context.pushReplacement(LoanPaths.application(app.id));
  }

  // ── Navigation ───────────────────────────────────────────────────────

  bool get _canLeave =>
      !_sending &&
      _outcome != _Outcome.checking &&
      (_outcome != null || _step == _Step.amount);

  void _back() {
    if (_sending || _outcome == _Outcome.checking) return;
    if (_outcome != null) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _step = switch (_step) {
        _Step.amount => _Step.amount,
        _Step.summary => _Step.amount,
        _Step.documents => _Step.summary,
        _Step.review => _Step.documents,
      };
    });
  }

  void _goSummary() {
    setState(() {
      _step = _Step.summary;
      _changed = const {};
    });
    // Opened again long after the quote: re-check the figures once.
    final at = _quotedAt;
    if (at != null &&
        DateTime.now().difference(at) > const Duration(minutes: 10)) {
      _requestQuote(_principal!, _term!, compare: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final offerV = ref.watch(loanOfferProvider);
    final title = switch (_step) {
      _ when _outcome != null => 'สินเชื่อคนขับ',
      _Step.amount => 'เลือกยอดและระยะผ่อน',
      _Step.summary => 'สรุปข้อมูลสำคัญ',
      _Step.documents =>
        'เอกสารสินเชื่อ${_terms == null ? '' : ' ฉบับ ${_terms!.version}'}',
      _Step.review => 'ตรวจสอบก่อนส่ง',
    };
    return PopScope(
      canPop: _canLeave,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: LoanPage(
        title: title,
        footer: offerV.hasValue && !offerV.hasError
            ? _footer(offerV.requireValue)
            : null,
        body: LoanAsync<LoanOffer>(
          value: offerV,
          onRetry: () => ref.invalidate(loanOfferProvider),
          builder: (offer) {
            if (_outcome != null) return _outcomeBody();
            if (!offer.eligible) {
              return LoanList(
                children: [
                  LoanDeclineBlock(copy: loanDeclineCopy(offer.declineReason)),
                ],
              );
            }
            return switch (_step) {
              _Step.amount => _amountBody(offer),
              _Step.summary => _summaryBody(),
              _Step.documents => _documentsBody(),
              _Step.review => _reviewBody(),
            };
          },
        ),
      ),
    );
  }

  Widget? _footer(LoanOffer offer) {
    if (_outcome != null || !offer.eligible) return null;
    switch (_step) {
      case _Step.amount:
        final ok = _quoteCurrent && _quote!.canApply;
        return LoanFooterButtons(
          secondary: 'กลับ',
          onSecondary: () => Navigator.of(context).maybePop(),
          primary: 'ถัดไป',
          onPrimary: ok ? _goSummary : null,
        );
      case _Step.summary:
        final ok = _quoteCurrent && _quote!.canApply;
        return LoanFooterButtons(
          note: 'ขั้นถัดไปคืออ่านเอกสาร ยังไม่ใช่การส่งคำขอ',
          secondary: 'แก้ไขยอด',
          onSecondary: () => setState(() => _step = _Step.amount),
          primary: 'ถัดไป: อ่านเอกสาร',
          onPrimary: ok ? _goDocuments : null,
        );
      case _Step.documents:
        return LoanFooterButtons(
          note: _terms != null && !_allTicked
              ? 'ติ๊กให้ครบทั้งสองข้อเพื่อไปต่อ'
              : null,
          secondary: 'กลับ',
          onSecondary: _back,
          primary: 'ถัดไป',
          onPrimary: _allTicked && !_termsLoading
              ? () => setState(() => _step = _Step.review)
              : null,
        );
      case _Step.review:
        return LoanFooterButtons(
          secondary: 'กลับ',
          onSecondary: _back,
          primary: 'ยืนยันส่งคำขอ',
          loading: _sending,
          onPrimary: _allTicked && _quoteCurrent ? _send : null,
        );
    }
  }

  // ── Screen 3: amount & term ──────────────────────────────────────────

  Widget _amountBody(LoanOffer offer) {
    final p = context.palette;
    final q = _quoteCurrent ? _quote : null;
    final problem = q == null
        ? null
        : loanProblemCopy(q, principal: _principal ?? 0, termDays: _term ?? 0);
    final amountProblem =
        q?.problem == 'AMOUNT_TOO_LOW' || q?.problem == 'AMOUNT_ABOVE_LIMIT';
    final terms = termChoices(offer.minTermDays, offer.maxTermDays);
    return LoanList(
      children: [
        Text(
          'ต้องการกู้เท่าไร',
          style: AppTypography.heading6.copyWith(color: p.textPrimary),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _amount,
          keyboardType: TextInputType.number,
          inputFormatters: [_ThousandsFormatter()],
          style: AppTypography.heading3.copyWith(color: p.textPrimary),
          decoration: InputDecoration(
            prefixText: '฿  ',
            hintText: 'เช่น 3,000',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: (_) => _inputsChanged(debounce: true),
        ),
        const SizedBox(height: 6),
        Text(
          'กู้ได้ ${formatBahtGroup(offer.minPrincipal)} – ${bahtWords(offer.maxPrincipal)}',
          style: AppTypography.caption5.copyWith(color: p.textSecondary),
        ),
        if (amountProblem && problem != null) _problemLine(problem),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final a in amountChoices(
              offer.minPrincipal,
              offer.maxPrincipal,
            ))
              ChoiceChip(
                label: Text(
                  a == offer.maxPrincipal ? 'สูงสุด' : formatBahtGroup(a),
                ),
                selected: _principal == a,
                onSelected: (_) => _setPrincipal(a),
              ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          'ผ่อนกี่วัน',
          style: AppTypography.heading6.copyWith(color: p.textPrimary),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final t in terms)
              ChoiceChip(
                label: Text('$t'),
                selected: !_customTerm && _term == t,
                onSelected: (_) => _setTerm(t),
              ),
            ChoiceChip(
              label: const Text('กำหนดเอง'),
              selected: _customTerm,
              onSelected: (_) =>
                  _setTerm(_term ?? offer.minTermDays, custom: true),
            ),
          ],
        ),
        if (_customTerm) _stepper(offer),
        if (!amountProblem && problem != null) _problemLine(problem),
        const SizedBox(height: 16),
        _costBlock(),
        const SizedBox(height: 8),
        Text(
          'เงินยังไม่โอนจนกว่าเจ้าหน้าที่อนุมัติ',
          style: AppTypography.caption5.copyWith(color: p.textSecondary),
        ),
      ],
    );
  }

  Widget _stepper(LoanOffer offer) {
    final t = _term ?? offer.minTermDays;
    void step(int d) => _setTerm(
      (t + d).clamp(offer.minTermDays, offer.maxTermDays),
      custom: true,
    );
    Widget btn(IconData icon, int d, String label) => GestureDetector(
      onLongPress: () => step(d * 5),
      child: IconButton.outlined(
        tooltip: label,
        onPressed: () => step(d),
        icon: Icon(icon),
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          btn(Icons.remove, -1, 'ลด 1 วัน'),
          Expanded(
            child: Text(
              '$t วัน',
              textAlign: TextAlign.center,
              style: AppTypography.heading5.copyWith(
                color: context.palette.textPrimary,
              ),
            ),
          ),
          btn(Icons.add, 1, 'เพิ่ม 1 วัน'),
        ],
      ),
    );
  }

  Widget _problemLine(LoanProblemCopy problem) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: LoanBanner(
      symbol: '⚠',
      title: problem.line,
      tone: LoanTone.warning,
      actions: [
        if (problem.fixLabel != null)
          TextButton(
            onPressed: () {
              if (problem.fixPrincipal != null) {
                _setPrincipal(problem.fixPrincipal!);
              }
              if (problem.fixTermDays != null) {
                final custom = !termChoicesContain(problem.fixTermDays!);
                _setTerm(problem.fixTermDays!, custom: custom);
              }
            },
            child: Text(problem.fixLabel!),
          ),
      ],
    ),
  );

  bool termChoicesContain(int t) {
    final o = ref.read(loanOfferProvider).asData?.value;
    return o != null && termChoices(o.minTermDays, o.maxTermDays).contains(t);
  }

  Widget _costBlock() {
    final p = context.palette;
    if (_quoteError != null && !_quoting) {
      return LoanBanner(
        symbol: '⚠',
        title: 'คำนวณค่างวดไม่สำเร็จ',
        lines: const ['ตรวจสอบอินเทอร์เน็ตแล้วลองอีกครั้ง'],
        tone: LoanTone.warning,
        actions: [
          TextButton(
            onPressed: () => _requestQuote(_principal!, _term!),
            child: const Text('ลองอีกครั้ง'),
          ),
        ],
      );
    }
    final q = _quote;
    String? placeholder;
    if (_principal == null || _term == null || q == null) {
      placeholder = _quoting
          ? 'กำลังคำนวณ…'
          : 'ใส่ยอดและเลือกจำนวนวันเพื่อดูค่างวด';
    } else if (q.problem != null || q.disclosure == null) {
      placeholder = _quoting
          ? 'กำลังคำนวณ…'
          : 'ปรับยอดหรือจำนวนวันเพื่อดูค่างวด';
    }
    final header = Row(
      children: [
        Expanded(
          child: Text(
            'ค่าใช้จ่ายของคุณ',
            style: AppTypography.caption3.copyWith(
              color: p.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (_quoting || !_quoteCurrent && q != null)
          Text(
            '⟳ กำลังคำนวณ…',
            style: AppTypography.caption5.copyWith(color: p.textSecondary),
          ),
      ],
    );
    if (placeholder != null) {
      return LoanCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            header,
            const SizedBox(height: 8),
            Text(
              placeholder,
              style: AppTypography.caption4.copyWith(color: p.textSecondary),
            ),
          ],
        ),
      );
    }
    final d = q!.disclosure!;
    return LoanCostCard(
      title: header,
      greyed: !_quoteCurrent,
      dailyInstalment: d.dailyInstalment,
      termDays: q.termDays,
      scheduledTotal: q.scheduledTotal,
      annualRateBps: d.annualRateBps,
      totalFees: d.totalFees,
      maxTotalInterest: d.maxTotalInterest,
      maxTotalRepayment: d.maxTotalRepayment,
    );
  }

  // ── Screen 4: key facts ──────────────────────────────────────────────

  Widget _summaryBody() {
    final p = context.palette;
    final q = _quote;
    final d = q?.disclosure;
    if (q == null || d == null || !_quoteCurrent) {
      if (_quoteError != null) {
        return LoanMessage(
          title: 'โหลดข้อมูลสินเชื่อไม่สำเร็จ',
          actionLabel: 'ลองอีกครั้ง',
          onAction: () => _requestQuote(_principal!, _term!, compare: true),
        );
      }
      return const LoanSkeleton(lines: 6);
    }
    return LoanList(
      children: [
        if (_changed.isNotEmpty)
          const LoanBanner(
            symbol: 'ⓘ',
            title: 'ตัวเลขมีการปรับปรุง กรุณาตรวจสอบอีกครั้ง',
          ),
        Text(
          'ยอดกู้ ${bahtWords(q.principal)} · ${q.termDays} วัน',
          style: AppTypography.heading6.copyWith(color: p.textPrimary),
        ),
        const SizedBox(height: 8),
        LoanCostCard(
          dailyInstalment: d.dailyInstalment,
          termDays: q.termDays,
          scheduledTotal: q.scheduledTotal,
          annualRateBps: d.annualRateBps,
          totalFees: d.totalFees,
          maxTotalInterest: d.maxTotalInterest,
          maxTotalRepayment: d.maxTotalRepayment,
          changed: _changed,
        ),
        const SizedBox(height: 6),
        Text(
          'ดอกเบี้ยตามตาราง ${baht2(q.scheduledTotal - q.principal)} · ถ้าหักไม่ได้บางวัน ดอกเบี้ยจะคิดตามวันที่ยอดค้างอยู่ สูงสุดไม่เกิน ${baht2(d.maxTotalInterest)}',
          style: AppTypography.caption5.copyWith(color: p.textSecondary),
        ),
        const LoanSectionTitle('การผ่อน'),
        const LoanBullet('เริ่มหักวันถัดจากวันที่ได้รับเงิน'),
        if (d.keepFloorThb > 0)
          LoanBullet(
            'รายได้ ${bahtWords(d.keepFloorThb)}แรกของทุกวันไม่ถูกหัก',
          ),
        if (d.deductionRateBps > 0)
          LoanBullet(
            'หักไม่เกิน ${percentFromBps(d.deductionRateBps)} ของรายได้ในวันนั้น',
          ),
        const LoanSectionTitle('สิทธิของคุณ'),
        const LoanBullet('จ่ายก่อนกำหนดได้ ไม่มีค่าปรับ'),
        LoanBullet(coolingOffLine(d.coolingOffDays)),
        const LoanBullet('ยกเลิกการหักอัตโนมัติได้ทุกเมื่อ (หนี้ยังคงอยู่)'),
      ],
    );
  }

  // ── Screen 5: documents ──────────────────────────────────────────────

  Widget _documentsBody() {
    final p = context.palette;
    if (_termsLoading) return const LoanSkeleton(lines: 6);
    final terms = _terms;
    if (_termsError || terms == null) {
      return LoanMessage(
        title: 'โหลดเอกสารไม่สำเร็จ',
        actionLabel: 'ลองอีกครั้ง',
        onAction: () => _loadTerms(changedOnServer: _termsChanged),
      );
    }
    final q = _quote;
    final shared = terms.shared;
    final sharedRead = shared.every((d) => _read.contains(d.kind));
    return LoanList(
      children: [
        if (_termsChanged)
          LoanBanner(
            symbol: 'ⓘ',
            title:
                'เงื่อนไขสินเชื่อมีการปรับปรุง กรุณาอ่านและยืนยันอีกครั้ง (ฉบับ ${terms.version})',
          ),
        if (_docsNotice != null)
          LoanBanner(symbol: 'ⓘ', title: _docsNotice!, tone: LoanTone.warning),
        if (q?.disclosure != null)
          Text(
            'ตัวเลขของคุณ: กู้ ${bahtWords(q!.principal)} · ${q.termDays} วัน · ผ่อนวันละ ${baht2(q.disclosure!.dailyInstalment)}',
            style: AppTypography.caption5.copyWith(color: p.textSecondary),
          ),
        const SizedBox(height: 8),
        Text(
          'เปิดอ่านให้ครบทั้ง ${terms.documents.length} ฉบับ',
          style: AppTypography.caption3.copyWith(
            color: p.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        LoanCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < terms.documents.length; i++) ...[
                if (i > 0) Divider(height: 1, color: p.border),
                _docRow(terms.documents[i], i),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        _tick(
          value: _tickShared,
          enabled: sharedRead,
          text:
              'ข้าพเจ้าได้อ่านและยอมรับ${shared.map((d) => d.title).join(' และ ')}',
          disabledWhy:
              'ยังกดไม่ได้: อ่าน${shared.where((d) => !_read.contains(d.kind)).map((d) => d.title).join(' และ ')}ก่อน',
          onChanged: (v) => setState(() => _tickShared = v),
        ),
        for (final d in terms.separate)
          _tick(
            value: _tickSeparate[d.kind] == true,
            enabled: _read.contains(d.kind),
            text: separateConsentText(d),
            disabledWhy: 'ยังกดไม่ได้: อ่าน${d.title}ก่อน',
            onChanged: (v) => setState(() => _tickSeparate[d.kind] = v),
          ),
      ],
    );
  }

  Widget _docRow(LoanDocument d, int i) {
    final p = context.palette;
    final read = _read.contains(d.kind);
    return InkWell(
      onTap: () => _openDoc(i),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              SizedBox(
                width: 86,
                child: Text(
                  read ? '✓ อ่านแล้ว' : '○ ยังไม่อ่าน',
                  style: AppTypography.caption5.copyWith(
                    color: read ? loanGreen : p.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  d.separate ? '${d.title} (แยกต่างหาก)' : d.title,
                  style: AppTypography.caption4.copyWith(color: p.textPrimary),
                ),
              ),
              Icon(Icons.chevron_right, color: p.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  /// ConsentTick: empty on open, the whole row is the target, unticking
  /// always allowed, a disabled one says why in words.
  Widget _tick({
    required bool value,
    required bool enabled,
    required String text,
    required String disabledWhy,
    required ValueChanged<bool> onChanged,
  }) {
    final p = context.palette;
    return CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      value: value,
      activeColor: loanGreen,
      onChanged: enabled || value ? (v) => onChanged(v ?? false) : null,
      title: Text(
        text,
        style: AppTypography.caption4.copyWith(color: p.textPrimary),
      ),
      subtitle: enabled || value
          ? null
          : Text(
              '($disabledWhy)',
              style: AppTypography.caption5.copyWith(color: p.textSecondary),
            ),
    );
  }

  // ── Screen 6: review ─────────────────────────────────────────────────

  Widget _reviewBody() {
    final p = context.palette;
    final q = _quote!;
    final d = q.disclosure!;
    final terms = _terms!;
    Widget edit(String label, VoidCallback onTap) =>
        TextButton(onPressed: _sending ? null : onTap, child: Text(label));
    TextStyle body() => AppTypography.caption4.copyWith(color: p.textPrimary);
    return LoanList(
      children: [
        LoanSectionTitle(
          'ยอดและระยะผ่อน',
          trailing: edit('แก้ไข', () => setState(() => _step = _Step.amount)),
        ),
        Text('${bahtWords(q.principal)} · ${q.termDays} วัน', style: body()),
        Text('ผ่อนวันละ ${baht2(d.dailyInstalment)}', style: body()),
        const LoanSectionTitle('ค่าใช้จ่าย'),
        Text('ยอดรวมที่ต้องจ่าย ${baht2(q.scheduledTotal)}', style: body()),
        Text(
          'ดอกเบี้ย ${percentFromBps(d.annualRateBps)} ต่อปี · ค่าธรรมเนียม ${baht2(d.totalFees)}',
          style: body(),
        ),
        Text(
          'ดอกเบี้ยสูงสุดกรณีแย่ที่สุด ${baht2(d.maxTotalInterest)}',
          style: body(),
        ),
        LoanSectionTitle(
          'เอกสารที่ยอมรับ ฉบับ ${terms.version}',
          trailing: edit(
            'อ่านอีกครั้ง',
            () => setState(() => _step = _Step.documents),
          ),
        ),
        LoanBullet(terms.shared.map((e) => e.title).join(' และ '), symbol: '✓'),
        for (final s in terms.separate)
          LoanBullet('${s.title} (แยก)', symbol: '✓'),
        const LoanSectionTitle('หลังส่งคำขอ'),
        Text(
          'เจ้าหน้าที่จะพิจารณาก่อน เงินยังไม่โอนตอนนี้ เราจะแจ้งผลทางการแจ้งเตือน',
          style: body(),
        ),
      ],
    );
  }

  // ── Outcomes ─────────────────────────────────────────────────────────

  Widget _outcomeBody() {
    void home() => context.go(AppRoutes.homeNamedPage);
    switch (_outcome!) {
      case _Outcome.declined:
        final rules = ref.watch(loanEligibilityProvider).asData?.value.rules;
        return LoanList(
          children: [
            LoanDeclineBlock(
              copy: loanDeclineCopy(_declineReason, rules: rules),
            ),
            const SizedBox(height: 12),
            LoanSecondaryButton('กลับหน้าหลัก', onPressed: home),
          ],
        );
      case _Outcome.conflict:
        return LoanMessage(
          symbol: 'ⓘ',
          title: 'คุณมีสินเชื่อหรือคำขอที่ค้างอยู่แล้ว',
          actionLabel: 'ดูรายการของฉัน',
          onAction: () => context.pushReplacement(LoanPaths.applications),
          secondaryLabel: 'กลับหน้าหลัก',
          onSecondary: home,
        );
      case _Outcome.checking:
        return const LoanMessage(
          symbol: '⟳',
          title: 'ยังไม่แน่ใจว่าส่งคำขอสำเร็จหรือไม่',
          body: 'กำลังตรวจสอบ…',
        );
      case _Outcome.notSent:
        return LoanMessage(
          title: 'ส่งคำขอไม่สำเร็จ ยังไม่มีคำขอใหม่ในระบบ',
          actionLabel: 'ส่งอีกครั้ง',
          onAction: _send,
          secondaryLabel: 'กลับ',
          onSecondary: () => setState(() {
            _outcome = null;
            _step = _Step.review;
          }),
        );
      case _Outcome.checkFailed:
        return LoanMessage(
          title: 'ยังตรวจสอบไม่ได้ กรุณาลองอีกครั้ง',
          actionLabel: 'ตรวจสอบอีกครั้ง',
          onAction: () =>
              _check(_principal!, _term!, _sentAt ?? DateTime.now()),
        );
      case _Outcome.failed:
        return LoanMessage(
          title: 'ส่งคำขอไม่สำเร็จ กรุณาลองอีกครั้ง',
          actionLabel: 'ลองอีกครั้ง',
          onAction: _send,
          secondaryLabel: 'กลับ',
          onSecondary: () => setState(() {
            _outcome = null;
            _step = _Step.review;
          }),
        );
    }
  }
}

/// `3,000` (no unit) for chips and the range line.
String formatBahtGroup(double v) => NumberFormat('#,##0').format(v.round());

/// Digits only, shown with thousands separators.
class _ThousandsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue();
    final capped = digits.length > 9 ? digits.substring(0, 9) : digits;
    final text = NumberFormat('#,##0').format(int.parse(capped));
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
