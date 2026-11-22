import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:massdrive/core/constants/app_routes.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/theme/app_palette.dart';
import 'package:massdrive/features/loans/data/loan_api.dart';
import 'package:massdrive/features/loans/domain/loan_copy.dart';
import 'package:massdrive/features/loans/domain/loan_format.dart';
import 'package:massdrive/features/loans/domain/loan_models.dart';
import 'package:massdrive/features/loans/domain/loan_paths.dart';
import 'package:massdrive/features/loans/presentation/loan_providers.dart';
import 'package:massdrive/features/loans/presentation/screens/loan_document_reader.dart';
import 'package:massdrive/features/loans/presentation/widgets/loan_ui.dart';

/// Screen 10 (design 10B): "กำลังดำเนินการ" on top, "ที่ผ่านมา" below.
class LoanApplicationsScreen extends ConsumerWidget {
  const LoanApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final v = ref.watch(loanApplicationsProvider);
    return LoanPage(
      title: 'คำขอสินเชื่อของฉัน',
      body: LoanAsync<List<LoanApplication>>(
        value: v,
        onRetry: () => ref.invalidate(loanApplicationsProvider),
        builder: (apps) {
          final p = context.palette;
          final pending = [
            for (final a in apps)
              if (a.status == LoanApplicationStatus.pending) a,
          ];
          final past = [
            for (final a in apps)
              if (a.status != LoanApplicationStatus.pending) a,
          ];
          if (apps.isEmpty) {
            final eligible =
                ref.watch(loanOfferProvider).asData?.value.eligible == true;
            return LoanMessage(
              symbol: 'ⓘ',
              title: 'ยังไม่มีคำขอสินเชื่อ',
              body: 'เมื่อคุณยื่นคำขอ จะแสดงที่นี่',
              secondaryLabel: eligible ? 'ดูสินเชื่อคนขับ' : null,
              onSecondary: () => context.push(LoanPaths.offer),
            );
          }
          return LoanList(
            onRefresh: () => ref.refresh(loanApplicationsProvider.future),
            children: [
              if (pending.isNotEmpty) ...[
                const LoanSectionTitle('กำลังดำเนินการ'),
                for (final a in pending) _PendingCard(app: a),
              ],
              if (past.isNotEmpty) ...[
                const LoanSectionTitle('ที่ผ่านมา'),
                LoanCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (var i = 0; i < past.length; i++) ...[
                        if (i > 0) Divider(height: 1, color: p.border),
                        _PastRow(app: past[i]),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// "อนุมัติ 2,000 จาก 3,000 บาท" when lower, else the amount.
String applicationAmountText(LoanApplication a) =>
    a.status == LoanApplicationStatus.approved && a.approvedLower
    ? 'อนุมัติ ${formatBahtNumberShort(a.approvedPrincipal!)} จาก ${bahtWords(a.principal)}'
    : bahtWords(a.shownPrincipal);

String formatBahtNumberShort(double v) => bahtWords(v).replaceAll(' บาท', '');

class _PendingCard extends ConsumerWidget {
  const _PendingCard({required this.app});

  final LoanApplication app;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    return LoanCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '◷ รอพิจารณา · ${bahtWords(app.principal)} · ${app.termDays} วัน',
            style: AppTypography.caption3.copyWith(
              color: p.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'รอเจ้าหน้าที่อนุมัติ${app.createdAt == null ? '' : ' · ส่ง ${formatBangkokDate(app.createdAt!)}'}',
            style: AppTypography.caption5.copyWith(color: p.textSecondary),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: LoanSecondaryButton(
                  'ยกเลิกคำขอ',
                  onPressed: () => confirmCancelApplication(context, ref, app),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: LoanPrimaryButton(
                  'ดูคำขอ',
                  onPressed: () => context.push(LoanPaths.application(app.id)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PastRow extends StatelessWidget {
  const _PastRow({required this.app});

  final LoanApplication app;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final chip = applicationChip(app.status);
    final date = app.reviewedAt ?? app.createdAt;
    return InkWell(
      onTap: () => context.push(
        app.status == LoanApplicationStatus.approved && app.loanId != null
            ? LoanPaths.loan(app.loanId!)
            : LoanPaths.application(app.id),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 6, 6),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${chip.symbol} ${chip.label} · ${applicationAmountText(app)}${date == null ? '' : ' · ${formatBangkokDate(date)}'}',
                    style: AppTypography.caption4.copyWith(
                      color: p.textPrimary,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(44, 36),
                      ),
                      onPressed: () =>
                          context.push(LoanPaths.applicationDocuments(app.id)),
                      child: const Text('เอกสาร'),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: p.textSecondary),
          ],
        ),
      ),
    );
  }
}

/// The two-step cancel (ConfirmSheet), then `POST …/cancel`. Returns true
/// when the application was withdrawn.
Future<bool> confirmCancelApplication(
  BuildContext context,
  WidgetRef ref,
  LoanApplication app,
) async {
  final ok = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: context.palette.sheet,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheet) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'ยกเลิกคำขอนี้?',
              style: AppTypography.heading5.copyWith(
                color: sheet.palette.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'คำขอ ${bahtWords(app.principal)} · ${app.termDays} วัน จะถูกยกเลิก\nยื่นคำขอใหม่ได้ภายหลัง',
              style: AppTypography.caption4.copyWith(
                color: sheet.palette.textPrimary,
              ),
            ),
            const SizedBox(height: 18),
            LoanFooterButtons(
              secondary: 'ไม่ยกเลิก',
              onSecondary: () => Navigator.of(sheet).pop(false),
              primary: 'ยกเลิกคำขอ',
              onPrimary: () => Navigator.of(sheet).pop(true),
            ),
          ],
        ),
      ),
    ),
  );
  if (ok != true || !context.mounted) return false;
  try {
    await ref.read(loanApiProvider).cancelApplication(app.id);
    LoanUpdates.instance.notifyChanged();
    if (context.mounted) showLoanSnack(context, 'ยกเลิกคำขอแล้ว');
    return true;
  } on LoanApiException catch (e) {
    if (!context.mounted) return false;
    if (e.lendingOff) {
      leaveLoans(context);
    } else if (e.statusCode == 409) {
      showLoanSnack(context, 'คำขอนี้ได้รับการพิจารณาแล้ว จึงยกเลิกไม่ได้');
      LoanUpdates.instance.notifyChanged();
    } else {
      showLoanSnack(
        context,
        'ยกเลิกไม่สำเร็จ กรุณาลองอีกครั้ง คำขอยังรอพิจารณาอยู่',
      );
    }
    return false;
  }
}

/// Screens 7 (waiting, 7E), 8 (approved, 8A), 9 (rejected, 9E), and the
/// record page of a declined or cancelled application — one page by status.
class LoanApplicationScreen extends ConsumerWidget {
  const LoanApplicationScreen({super.key, required this.id, this.initial});

  final String id;

  /// The `POST /loans` 202 body (same shape as a list row): shown at once,
  /// and kept while the list hasn't caught up with it yet.
  final LoanApplication? initial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final v = ref.watch(loanApplicationsProvider);
    final listed = v.asData?.value.where((a) => a.id == id).firstOrNull;
    final app = listed ?? (initial?.id == id ? initial : null);
    if (app != null) {
      return switch (app.status) {
        LoanApplicationStatus.approved => _ApprovedView(app: app),
        LoanApplicationStatus.rejected => _RejectedView(app: app),
        _ => _RecordView(app: app),
      };
    }
    return LoanAsync<List<LoanApplication>>(
      value: v,
      onRetry: () => ref.invalidate(loanApplicationsProvider),
      builder: (apps) {
        // A stale push or link: the list shows where things stand.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            context.pushReplacement(LoanPaths.applications);
          }
        });
        return const SizedBox.shrink();
      },
    ).wrapPage(
      context,
      title: 'คำขอสินเชื่อ',
      hasValue: v.hasValue && !v.hasError,
    );
  }
}

extension on Widget {
  /// Loading and error states still get the page chrome.
  Widget wrapPage(
    BuildContext context, {
    required String title,
    required bool hasValue,
  }) => hasValue ? this : LoanPage(title: title, body: this);
}

/// 7E: the application's own page — figures, a dated log, its documents.
class _RecordView extends ConsumerWidget {
  const _RecordView({required this.app});

  final LoanApplication app;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final docs = ref.watch(applicationDocumentsProvider(app.id)).asData?.value;
    final pending = app.status == LoanApplicationStatus.pending;
    final d = app.disclosure;
    final chip = applicationChip(app.status);
    Widget log(String when, String what) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              when,
              style: AppTypography.caption5.copyWith(color: p.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              what,
              style: AppTypography.caption4.copyWith(color: p.textPrimary),
            ),
          ),
        ],
      ),
    );
    final closedWord = switch (app.status) {
      LoanApplicationStatus.cancelled => 'ยกเลิกคำขอ',
      LoanApplicationStatus.declined => 'ไม่ผ่านเกณฑ์ของระบบ',
      _ => 'พิจารณาแล้ว',
    };
    return LoanPage(
      title: 'คำขอสินเชื่อ',
      trailing: LoanChipView(chip),
      footer: pending
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'เราจะแจ้งผลทางการแจ้งเตือน',
                  textAlign: TextAlign.center,
                  style: AppTypography.caption5.copyWith(
                    color: p.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                LoanSecondaryButton(
                  'ยกเลิกคำขอ',
                  onPressed: () async {
                    final done = await confirmCancelApplication(
                      context,
                      ref,
                      app,
                    );
                    if (done && context.mounted) {
                      context.pushReplacement(LoanPaths.applications);
                    }
                  },
                ),
              ],
            )
          : null,
      body: LoanList(
        onRefresh: () async {
          ref.invalidate(applicationDocumentsProvider(app.id));
          ref.invalidate(loanApplicationsProvider);
          await ref.read(loanApplicationsProvider.future);
        },
        children: [
          if (app.status == LoanApplicationStatus.declined) ...[
            LoanBanner(
              symbol: '⊘',
              title: app.declineReason != null
                  ? loanDeclineCopy(app.declineReason).heading
                  : (app.reviewNote ?? 'ไม่ผ่านเกณฑ์ของระบบในขณะยื่นคำขอ'),
              lines: const ['ไม่มีค่าใช้จ่ายใดๆ จากคำขอนี้'],
              tone: LoanTone.neutral,
            ),
          ],
          const LoanSectionTitle('ตัวเลขที่ขอ'),
          LoanFactRow(
            'ยอดกู้',
            '${bahtWords(app.principal)} · ${app.termDays} วัน',
            bold: true,
          ),
          LoanFactRow('ผ่อนวันละ', baht2(app.dailyInstalment)),
          LoanFactRow(
            'ดอกเบี้ย',
            '${percentFromBps(app.annualRateBps)} ต่อปี · ค่าธรรมเนียม ${baht2(d?.totalFees ?? 0)}',
          ),
          if (d != null) ...[
            LoanFactRow(
              'ดอกเบี้ยสูงสุดกรณีแย่ที่สุด',
              baht2(d.maxTotalInterest),
            ),
            LoanFactRow(
              'ยอดรวมสูงสุดกรณีแย่ที่สุด',
              baht2(d.maxTotalRepayment),
            ),
          ],
          const LoanSectionTitle('บันทึก'),
          if (app.createdAt != null)
            log(formatBangkokDateTime(app.createdAt!), 'ส่งคำขอ'),
          if (docs?.acceptedAt != null)
            log(
              formatBangkokDateTime(docs!.acceptedAt!),
              'ยอมรับเอกสาร ฉบับ ${docs.terms.version}',
            ),
          if (pending)
            log('—', 'รอเจ้าหน้าที่อนุมัติ')
          else if (app.reviewedAt != null)
            log(formatBangkokDateTime(app.reviewedAt!), closedWord),
          if (app.reviewNote != null &&
              app.status != LoanApplicationStatus.declined)
            log('', 'หมายเหตุจากเจ้าหน้าที่: ${app.reviewNote}'),
          const LoanSectionTitle('เอกสาร'),
          if (docs == null)
            LoanLink(
              'ดูเอกสาร',
              onTap: () => context.push(LoanPaths.applicationDocuments(app.id)),
            )
          else
            for (var i = 0; i < docs.terms.documents.length; i++)
              LoanLink(
                docs.terms.documents[i].title,
                onTap: () => LoanDocumentReader.open(
                  context,
                  documents: docs.terms.documents,
                  index: i,
                  version: docs.terms.version,
                  forAcceptance: false,
                ),
              ),
        ],
      ),
    );
  }
}

/// 8A: the received amount large, then the terms. The loan's figures are
/// the truth for the instalment; the application's are what was asked.
class _ApprovedView extends ConsumerWidget {
  const _ApprovedView({required this.app});

  final LoanApplication app;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loanId = app.loanId;
    if (loanId == null) return _RecordView(app: app);
    final v = ref.watch(loanDetailProvider(loanId));
    return LoanPage(
      title: 'สินเชื่อได้รับอนุมัติ',
      footer: v.hasValue
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LoanPrimaryButton(
                  'ถอนเงิน',
                  onPressed: () => context.push(AppRoutes.cashWalletNamedPage),
                ),
                const SizedBox(height: 10),
                LoanSecondaryButton(
                  'ดูสินเชื่อ',
                  onPressed: () => context.push(LoanPaths.loan(loanId)),
                ),
              ],
            )
          : null,
      body: LoanAsync<LoanDetail>(
        value: v,
        onRetry: () => ref.invalidate(loanDetailProvider(loanId)),
        builder: (detail) {
          final l = detail.loan;
          if (l.status == LoanStatus.paidOff) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                context.pushReplacement(LoanPaths.loan(l.id));
              }
            });
            return const SizedBox.shrink();
          }
          final p = context.palette;
          final today = bangkokDay(DateTime.now());
          final start = l.scheduleStart;
          // Asked (the application row) vs paid out (the loan, which is
          // also what approved_principal says).
          final lower = app.approvedLower || l.principal < app.principal;
          final tomorrow =
              start != null &&
              sameDay(start, today.add(const Duration(days: 1)));
          return LoanList(
            onRefresh: () => ref.refresh(loanDetailProvider(loanId).future),
            children: [
              if (l.isBehind || l.status == LoanStatus.writtenOff)
                LoanBanner(
                  symbol: '!',
                  title: l.status == LoanStatus.delinquent
                      ? 'สินเชื่อเลยกำหนดชำระแล้ว'
                      : 'มียอดผ่อนค้างอยู่',
                  tone: LoanTone.warning,
                  actions: [
                    TextButton(
                      onPressed: () => context.push(LoanPaths.catchUp(l.id)),
                      child: const Text('ดูวิธีชำระ'),
                    ),
                  ],
                ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  '✓ อนุมัติแล้ว',
                  style: AppTypography.caption2.copyWith(
                    color: loanGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  '${bahtShort(l.principal)} เข้ากระเป๋าเงินแล้ว',
                  textAlign: TextAlign.center,
                  style: AppTypography.heading3.copyWith(color: p.textPrimary),
                ),
              ),
              if (l.disbursedAt != null)
                Center(
                  child: Text(
                    formatBangkokDateTime(l.disbursedAt!),
                    style: AppTypography.caption5.copyWith(
                      color: p.textSecondary,
                    ),
                  ),
                ),
              if (lower)
                LoanBanner(
                  symbol: '!',
                  title: 'อนุมัติน้อยกว่าที่ขอ',
                  tone: LoanTone.warning,
                  lines: [
                    'คุณขอ ${bahtWords(app.principal)} ได้รับอนุมัติ ${bahtWords(l.principal)}',
                    'ค่างวดใหม่ วันละ ${baht2(l.dailyInstalment)} (เดิม ${baht2(app.dailyInstalment)})',
                    if (app.reviewNote != null)
                      'หมายเหตุจากเจ้าหน้าที่: ${app.reviewNote}',
                  ],
                )
              else if (app.reviewNote != null)
                LoanBanner(
                  symbol: 'ⓘ',
                  title: 'หมายเหตุจากเจ้าหน้าที่',
                  lines: [app.reviewNote!],
                  tone: LoanTone.neutral,
                ),
              const SizedBox(height: 8),
              LoanFactRow('ผ่อนวันละ', baht2(l.dailyInstalment), bold: true),
              LoanFactRow('จำนวนวัน', '${l.termDays} วัน'),
              if (start != null)
                LoanFactRow(
                  'เริ่มหัก',
                  '${tomorrow ? 'พรุ่งนี้ ' : ''}${formatDay(start)}',
                ),
              if (l.maturesOn != null)
                LoanFactRow('ครบกำหนด', formatDay(l.maturesOn!)),
              LoanFactRow('ยอดรวมตามตาราง', baht2(l.scheduledTotal)),
              LoanFactRow(
                'ดอกเบี้ย',
                '${percentFromBps(l.annualRateBps)} ต่อปี · ค่าธรรมเนียม ${baht2(l.disclosure.totalFees)}',
              ),
              const SizedBox(height: 10),
              if (l.coolingOffUntil != null)
                LoanBullet(
                  '${coolingOffLine(l.disclosure.coolingOffDays)} (${coolingOffUntilText(l.coolingOffUntil!)})',
                  symbol: 'ⓘ',
                ),
              if (l.keepFloorThb > 0)
                LoanBullet(
                  'รายได้ ${bahtWords(l.keepFloorThb)}แรกของวันไม่ถูกหัก',
                  symbol: 'ⓘ',
                ),
            ],
          );
        },
      ),
    );
  }
}

/// 9E: the reason in the admin's words, then what to do next.
class _RejectedView extends ConsumerWidget {
  const _RejectedView({required this.app});

  final LoanApplication app;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final offer = ref.watch(loanOfferProvider).asData?.value;
    final rules = ref.watch(loanEligibilityProvider).asData?.value.rules;
    final date = app.reviewedAt ?? app.createdAt;
    Widget step(String n, Widget child) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Text(
              n,
              style: AppTypography.caption3.copyWith(
                color: loanGreen,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
    final body = AppTypography.caption4.copyWith(color: p.textPrimary);
    return LoanPage(
      title: 'ผลการพิจารณา',
      footer: LoanPrimaryButton(
        'กลับหน้าหลัก',
        onPressed: () => context.go(AppRoutes.homeNamedPage),
      ),
      body: LoanList(
        onRefresh: () async {
          ref.invalidate(loanOfferProvider);
          ref.invalidate(loanApplicationsProvider);
          await ref.read(loanApplicationsProvider.future);
        },
        children: [
          Text(
            'ⓘ คำขอยังไม่ได้รับอนุมัติ',
            style: AppTypography.heading5.copyWith(color: p.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            '${bahtWords(app.principal)} · ${app.termDays} วัน${date == null ? '' : ' · ${formatBangkokDate(date)}'}',
            style: AppTypography.caption4.copyWith(color: p.textSecondary),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.only(left: 10),
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: p.border, width: 3)),
            ),
            child: Text(
              app.reviewNote ??
                  'เจ้าหน้าที่ไม่ได้ระบุเหตุผล หากต้องการทราบ ติดต่อฝ่ายช่วยเหลือ',
              style: body,
            ),
          ),
          const LoanSectionTitle('ทำอะไรต่อได้บ้าง'),
          step('1', Text('อ่านเหตุผลจากเจ้าหน้าที่ด้านบน', style: body)),
          if (offer != null)
            step(
              '2',
              offer.eligible
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ยื่นใหม่ได้ด้วยยอดที่น้อยลงหรือผ่อนนานขึ้น',
                          style: body,
                        ),
                        LoanLink(
                          'ดูสินเชื่อ',
                          onTap: () => context.push(LoanPaths.offer),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loanDeclineCopy(
                            offer.declineReason,
                            rules: rules,
                          ).heading,
                          style: body,
                        ),
                        if (loanDeclineCopy(offer.declineReason).action.label
                            case final label?)
                          LoanLink(
                            label,
                            onTap: () => runDeclineAction(
                              context,
                              loanDeclineCopy(offer.declineReason).action,
                            ),
                          ),
                      ],
                    ),
            ),
          step(
            offer != null ? '3' : '2',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('มีคำถาม', style: body),
                LoanLink(
                  'ติดต่อฝ่ายช่วยเหลือ',
                  onTap: () => openLoanSupport(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'ไม่มีค่าใช้จ่ายใดๆ จากคำขอนี้',
            style: AppTypography.caption4.copyWith(color: p.textSecondary),
          ),
          LoanLink(
            'ดูคำขอทั้งหมด',
            onTap: () => context.push(LoanPaths.applications),
          ),
        ],
      ),
    );
  }
}
