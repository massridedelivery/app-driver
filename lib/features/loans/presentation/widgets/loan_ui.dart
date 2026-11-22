import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:massdrive/common/widgets/appbar/base_appbar.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_routes.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/theme/app_palette.dart';
import 'package:massdrive/features/loans/data/loan_api.dart';
import 'package:massdrive/features/loans/domain/loan_copy.dart';
import 'package:massdrive/features/loans/domain/loan_format.dart';
import 'package:massdrive/features/loans/domain/loan_paths.dart';
import 'package:massdrive/features/support/presentation/screens/help_center_screen.dart';

/// Shared pieces of the loan screens (FE spec §C).

const loanGreen = AppColors.semanticSupportMintBgHigh;
const loanWarning = AppColors.foundationOrange500;

Color loanToneColor(BuildContext context, LoanTone tone) => switch (tone) {
  LoanTone.success => loanGreen,
  LoanTone.info => const Color(0xFF3B82F6),
  LoanTone.warning => loanWarning,
  LoanTone.neutral => context.palette.textSecondary,
};

Color loanCardSurface(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? const Color(0xFF262932)
    : Colors.white;

/// A page with the app bar and an explicit background.
class LoanPage extends StatelessWidget {
  const LoanPage({
    super.key,
    required this.title,
    required this.body,
    this.footer,
    this.trailing,
    this.onBack,
  });

  final String title;
  final Widget body;

  /// Sticky bottom area (buttons), kept above the system inset.
  final Widget? footer;
  final Widget? trailing;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.bg,
      appBar: CommonAppBar(
        titleText: title,
        showLeftIcon: true,
        onLeftTap: onBack,
        rightWidgets: [
          if (trailing != null)
            Padding(padding: const EdgeInsets.only(right: 12), child: trailing),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: body),
            if (footer != null)
              Container(
                decoration: BoxDecoration(
                  color: context.palette.bg,
                  border: Border(
                    top: BorderSide(color: context.palette.border),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: footer,
              ),
          ],
        ),
      ),
    );
  }
}

/// Scrollable padded content.
class LoanList extends StatelessWidget {
  const LoanList({super.key, required this.children, this.onRefresh});

  final List<Widget> children;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final list = ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: children,
    );
    return onRefresh == null
        ? list
        : RefreshIndicator(onRefresh: onRefresh!, child: list);
  }
}

class LoanCard extends StatelessWidget {
  const LoanCard({
    super.key,
    required this.child,
    this.borderColor,
    this.padding,
  });

  final Widget child;
  final Color? borderColor;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding ?? const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: loanCardSurface(context),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: borderColor ?? context.palette.border),
    ),
    child: child,
  );
}

class LoanChipView extends StatelessWidget {
  const LoanChipView(this.chip, {super.key});

  final LoanChip chip;

  @override
  Widget build(BuildContext context) {
    final c = loanToneColor(context, chip.tone);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.withValues(alpha: 0.5)),
      ),
      child: Text(
        '${chip.symbol} ${chip.label}',
        style: AppTypography.caption5.copyWith(
          color: c,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class LoanSectionTitle extends StatelessWidget {
  const LoanSectionTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 18, bottom: 8),
    child: Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: AppTypography.heading6.copyWith(
              color: context.palette.textPrimary,
            ),
          ),
        ),
        ?trailing,
      ],
    ),
  );
}

/// Label on the left, value on the right; wraps rather than truncates.
class LoanFactRow extends StatelessWidget {
  const LoanFactRow(
    this.label,
    this.value, {
    super.key,
    this.bold = false,
    this.isNew = false,
    this.greyed = false,
  });

  final String label;
  final String value;
  final bool bold;

  /// "● ใหม่": the figure changed on a re-quote (never colour alone).
  final bool isNew;
  final bool greyed;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = greyed ? p.textTertiary : p.textPrimary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              isNew ? '● $label (ใหม่)' : label,
              style: AppTypography.caption4.copyWith(
                color: greyed ? p.textTertiary : p.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: (bold ? AppTypography.caption3 : AppTypography.caption4)
                  .copyWith(
                    color: color,
                    fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The key-facts block (CostSummaryCard): the six lines, always in this
/// order. [scheduledTotal] is left out where the API has none.
class LoanCostCard extends StatelessWidget {
  const LoanCostCard({
    super.key,
    required this.dailyInstalment,
    required this.termDays,
    required this.annualRateBps,
    required this.totalFees,
    required this.maxTotalInterest,
    required this.maxTotalRepayment,
    this.scheduledTotal,
    this.title,
    this.greyed = false,
    this.changed = const {},
  });

  final double dailyInstalment;
  final int termDays;
  final int annualRateBps;
  final double totalFees;
  final double maxTotalInterest;
  final double maxTotalRepayment;
  final double? scheduledTotal;
  final Widget? title;
  final bool greyed;

  /// Lines that changed on a re-quote: 'daily', 'total', 'interest'.
  final Set<String> changed;

  @override
  Widget build(BuildContext context) {
    return LoanCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[title!, const SizedBox(height: 4)],
          LoanFactRow(
            'ผ่อนวันละ',
            baht2(dailyInstalment),
            bold: true,
            greyed: greyed,
            isNew: changed.contains('daily'),
          ),
          LoanFactRow('จำนวน', '$termDays วัน', greyed: greyed),
          if (scheduledTotal != null)
            LoanFactRow(
              'ยอดรวมที่ต้องจ่าย',
              baht2(scheduledTotal!),
              bold: true,
              greyed: greyed,
              isNew: changed.contains('total'),
            ),
          LoanFactRow(
            'ดอกเบี้ย',
            '${percentFromBps(annualRateBps)} ต่อปี',
            greyed: greyed,
          ),
          LoanFactRow('ค่าธรรมเนียม', baht2(totalFees), greyed: greyed),
          LoanFactRow(
            'ดอกเบี้ยสูงสุดกรณีแย่ที่สุด',
            baht2(maxTotalInterest),
            greyed: greyed,
            isNew: changed.contains('interest'),
          ),
          Text(
            '(กรณีแย่ที่สุด รวม ${baht2(maxTotalRepayment)})',
            textAlign: TextAlign.right,
            style: AppTypography.caption5.copyWith(
              color: context.palette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// A one-line bullet (✓, •, ⓘ…).
class LoanBullet extends StatelessWidget {
  const LoanBullet(this.text, {super.key, this.symbol = '•', this.color});

  final String text;
  final String symbol;
  final Color? color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 22,
          child: Text(
            symbol,
            style: AppTypography.caption4.copyWith(
              color: color ?? loanGreen,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: AppTypography.caption4.copyWith(
              color: context.palette.textPrimary,
            ),
          ),
        ),
      ],
    ),
  );
}

/// An icon + words banner (never colour alone).
class LoanBanner extends StatelessWidget {
  const LoanBanner({
    super.key,
    required this.symbol,
    required this.title,
    this.lines = const [],
    this.tone = LoanTone.info,
    this.actions = const [],
  });

  final String symbol;
  final String title;
  final List<String> lines;
  final LoanTone tone;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final c = loanToneColor(context, tone);
    final p = context.palette;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$symbol $title',
            style: AppTypography.caption3.copyWith(
              color: p.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          for (final l in lines) ...[
            const SizedBox(height: 3),
            Text(
              l,
              style: AppTypography.caption4.copyWith(color: p.textPrimary),
            ),
          ],
          if (actions.isNotEmpty) Wrap(spacing: 4, children: actions),
        ],
      ),
    );
  }
}

class LoanPrimaryButton extends StatelessWidget {
  const LoanPrimaryButton(
    this.label, {
    super.key,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 50,
    width: double.infinity,
    child: FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: loanGreen,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: loading ? null : onPressed,
      child: loading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: Colors.white,
              ),
            )
          : Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
    ),
  );
}

class LoanSecondaryButton extends StatelessWidget {
  const LoanSecondaryButton(this.label, {super.key, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 50,
    width: double.infinity,
    child: OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: context.palette.textPrimary,
        side: BorderSide(color: context.palette.border, width: 1.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onPressed,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
  );
}

/// Back-out and go-on side by side, the same size (FE rule 3).
class LoanFooterButtons extends StatelessWidget {
  const LoanFooterButtons({
    super.key,
    required this.secondary,
    required this.onSecondary,
    required this.primary,
    required this.onPrimary,
    this.loading = false,
    this.note,
  });

  final String secondary;
  final VoidCallback? onSecondary;
  final String primary;
  final VoidCallback? onPrimary;
  final bool loading;
  final String? note;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (note != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            note!,
            textAlign: TextAlign.center,
            style: AppTypography.caption5.copyWith(
              color: context.palette.textSecondary,
            ),
          ),
        ),
      Row(
        children: [
          Expanded(
            child: LoanSecondaryButton(
              secondary,
              onPressed: loading ? null : onSecondary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: LoanPrimaryButton(
              primary,
              onPressed: onPrimary,
              loading: loading,
            ),
          ),
        ],
      ),
    ],
  );
}

/// A tappable text row ‹ ลิงก์ ›, at least 44 dp tall.
class LoanLink extends StatelessWidget {
  const LoanLink(this.label, {super.key, required this.onTap, this.icon});

  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(10),
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: loanGreen),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              label,
              style: AppTypography.caption3.copyWith(
                color: loanGreen,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Icon(Icons.chevron_right, color: context.palette.textSecondary),
        ],
      ),
    ),
  );
}

class LoanSkeleton extends StatelessWidget {
  const LoanSkeleton({super.key, this.lines = 5});

  final int lines;

  @override
  Widget build(BuildContext context) {
    final c = context.palette.surfaceAlt;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (var i = 0; i < lines; i++)
          Container(
            height: i == 0 ? 56 : 18,
            margin: const EdgeInsets.only(bottom: 14),
            width: double.infinity,
            decoration: BoxDecoration(
              color: c == Colors.transparent
                  ? Colors.black12
                  : c.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const SizedBox.shrink(),
          ),
        Center(
          child: Text(
            'กำลังโหลด…',
            style: AppTypography.caption5.copyWith(
              color: context.palette.textTertiary,
            ),
          ),
        ),
      ],
    );
  }
}

/// A centred message with one action ("ลองอีกครั้ง", "กลับ").
class LoanMessage extends StatelessWidget {
  const LoanMessage({
    super.key,
    required this.title,
    this.body,
    this.actionLabel,
    this.onAction,
    this.secondaryLabel,
    this.onSecondary,
    this.symbol = '⚠',
  });

  final String title;
  final String? body;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 64, 24, 24),
      children: [
        Text(
          symbol,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 34, color: p.textSecondary),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppTypography.heading6.copyWith(color: p.textPrimary),
        ),
        if (body != null) ...[
          const SizedBox(height: 6),
          Text(
            body!,
            textAlign: TextAlign.center,
            style: AppTypography.caption4.copyWith(color: p.textSecondary),
          ),
        ],
        if (actionLabel != null) ...[
          const SizedBox(height: 20),
          LoanPrimaryButton(actionLabel!, onPressed: onAction),
        ],
        if (secondaryLabel != null) ...[
          const SizedBox(height: 10),
          LoanSecondaryButton(secondaryLabel!, onPressed: onSecondary),
        ],
      ],
    );
  }
}

/// Lending is off on this server: leave the loan screens for home, with no
/// message (FE rule 7).
void leaveLoans(BuildContext context) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (context.mounted) context.go(AppRoutes.homeNamedPage);
  });
}

/// The loading / error / 404 handling every loan screen shares.
class LoanAsync<T> extends StatelessWidget {
  const LoanAsync({
    super.key,
    required this.value,
    required this.onRetry,
    required this.builder,
    this.errorTitle = 'โหลดข้อมูลสินเชื่อไม่สำเร็จ',
    this.skeletonLines = 5,
  });

  final AsyncValue<T> value;
  final VoidCallback onRetry;
  final Widget Function(T data) builder;
  final String errorTitle;
  final int skeletonLines;

  @override
  Widget build(BuildContext context) {
    final v = value;
    if (v.hasValue && !v.hasError) return builder(v.requireValue);
    if (v.hasError) {
      final e = v.error;
      if (e is LoanApiException && e.lendingOff) {
        leaveLoans(context);
        return const SizedBox.shrink();
      }
      if (e is LoanApiException && e.notFound) {
        return LoanMessage(
          title: 'ไม่พบข้อมูลนี้',
          actionLabel: 'กลับ',
          onAction: () =>
              context.canPop() ? context.pop() : context.go(LoanPaths.offer),
        );
      }
      return LoanMessage(
        title: errorTitle,
        body: e is LoanApiException && e.network
            ? 'ตรวจสอบอินเทอร์เน็ตแล้วลองอีกครั้ง'
            : null,
        actionLabel: 'ลองอีกครั้ง',
        onAction: onRetry,
      );
    }
    return LoanSkeleton(lines: skeletonLines);
  }
}

void openLoanSupport(BuildContext context) {
  Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const HelpCenterScreen()));
}

void showLoanSnack(BuildContext context, String text) {
  ScaffoldMessenger.maybeOf(context)
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}

/// Opens what a T1 decline action points at. [loanId] / [applicationId]
/// are used for OPEN_LOAN / PENDING_APPLICATION when known.
void runDeclineAction(
  BuildContext context,
  LoanDeclineAction action, {
  String? loanId,
  String? applicationId,
}) {
  switch (action) {
    case LoanDeclineAction.none:
      return;
    case LoanDeclineAction.viewLoan:
      context.push(
        loanId != null ? LoanPaths.loan(loanId) : LoanPaths.applications,
      );
    case LoanDeclineAction.viewApplication:
      context.push(
        applicationId != null
            ? LoanPaths.application(applicationId)
            : LoanPaths.applications,
      );
    case LoanDeclineAction.settleDebt:
      context.push(AppRoutes.creditWalletNamedPage);
    case LoanDeclineAction.documents:
      context.push(AppRoutes.documentRegistrationChecklistNamedPage);
    case LoanDeclineAction.editProfile:
      context.push(AppRoutes.editProfileNamedPage);
    case LoanDeclineAction.payoutAccount:
      context.push(AppRoutes.documentRegistrationBankNamedPage);
    case LoanDeclineAction.support:
      openLoanSupport(context);
  }
}

/// The T1 block: heading, what to do, its button, the eligibility link.
class LoanDeclineBlock extends StatelessWidget {
  const LoanDeclineBlock({
    super.key,
    required this.copy,
    this.loanId,
    this.applicationId,
  });

  final LoanDeclineCopy copy;
  final String? loanId;
  final String? applicationId;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final label = copy.action.label;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '⊘ ยังขอสินเชื่อไม่ได้',
          style: AppTypography.heading5.copyWith(color: p.textPrimary),
        ),
        const SizedBox(height: 6),
        Text(
          copy.heading,
          style: AppTypography.caption2.copyWith(
            color: p.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'ทำอย่างไรได้บ้าง',
          style: AppTypography.caption4.copyWith(
            color: p.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          copy.hint,
          style: AppTypography.caption4.copyWith(color: p.textPrimary),
        ),
        if (label != null) ...[
          const SizedBox(height: 12),
          LoanPrimaryButton(
            label,
            onPressed: () => runDeclineAction(
              context,
              copy.action,
              loanId: loanId,
              applicationId: applicationId,
            ),
          ),
        ],
        LoanLink(
          'อ่านคุณสมบัติการขอสินเชื่อ',
          onTap: () => context.push(LoanPaths.eligibility),
        ),
      ],
    );
  }
}
