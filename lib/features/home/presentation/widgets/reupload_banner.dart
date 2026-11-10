import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_routes.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/theme/app_palette.dart';
import 'package:massdrive/features/document_registration/domain/document_reupload.dart';
import 'package:massdrive/features/document_registration/presentation/controllers/rejected_documents_provider.dart';

/// What home says about the driver's documents. None of these stops the
/// driver going online.
enum DocumentAlert { none, rejected, expiring, waiting }

/// Rejected wins (red, something to do), then expiring (amber, a new copy is
/// welcome), then waiting (neutral, nothing to do). [count] is how many
/// documents are in the winning state.
({DocumentAlert alert, int count}) documentAlertOf(List<ReuploadItem> open) {
  int count(ReuploadState s) => open.where((d) => d.state == s).length;
  final rejected = count(ReuploadState.rejected);
  if (rejected > 0) return (alert: DocumentAlert.rejected, count: rejected);
  final expiring = count(ReuploadState.expiring);
  if (expiring > 0) return (alert: DocumentAlert.expiring, count: expiring);
  final pending = count(ReuploadState.pending);
  if (pending > 0) return (alert: DocumentAlert.waiting, count: pending);
  return (alert: DocumentAlert.none, count: 0);
}

/// Home's document alert, from GET /api/driver/documents (one row per type).
({DocumentAlert alert, int count}) watchDocumentAlert(WidgetRef ref) =>
    documentAlertOf(ref.watch(reuploadDocumentsProvider).value ?? const []);

Color _alertColor(BuildContext context, DocumentAlert alert) => switch (alert) {
  DocumentAlert.rejected => AppColors.semanticErrorBgHigh,
  DocumentAlert.expiring => AppColors.foundationOrange500,
  _ => context.palette.textSecondary,
};

/// The status card's second line while a document is open: red "มีเอกสาร
/// ต้องอัปโหลดใหม่ ›", amber "เอกสารใกล้หมดอายุ ›" or neutral "เอกสารรอ
/// ตรวจสอบ ›". Taps open the checklist.
class DocumentAlertLine extends StatelessWidget {
  const DocumentAlertLine({super.key, required this.alert});

  final DocumentAlert alert;

  @override
  Widget build(BuildContext context) {
    final color = _alertColor(context, alert);
    final (icon, text) = switch (alert) {
      DocumentAlert.rejected => (
        Icons.error_outline_rounded,
        'มีเอกสารต้องอัปโหลดใหม่',
      ),
      DocumentAlert.expiring => (Icons.event_rounded, 'เอกสารใกล้หมดอายุ'),
      _ => (Icons.hourglass_top_rounded, 'เอกสารรอตรวจสอบ'),
    };
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () =>
          context.push(AppRoutes.documentRegistrationChecklistNamedPage),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption5.copyWith(color: color),
            ),
          ),
          Icon(Icons.chevron_right_rounded, size: 16, color: color),
        ],
      ),
    );
  }
}

/// On the profile menu icon: a red count of rejected documents, an amber
/// count of expiring ones, or a small neutral dot while documents wait for
/// review. Nothing otherwise.
class DocumentMenuBadge extends StatelessWidget {
  const DocumentMenuBadge({
    super.key,
    required this.alert,
    required this.count,
  });

  final DocumentAlert alert;
  final int count;

  @override
  Widget build(BuildContext context) {
    final color = _alertColor(context, alert);
    switch (alert) {
      case DocumentAlert.none:
        return const SizedBox.shrink();
      case DocumentAlert.waiting:
        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(color: context.palette.bg, width: 1.5),
          ),
        );
      case DocumentAlert.rejected:
      case DocumentAlert.expiring:
        return Container(
          constraints: const BoxConstraints(minWidth: 18),
          height: 18,
          padding: const EdgeInsets.symmetric(horizontal: 5),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: context.palette.bg, width: 1.5),
          ),
          child: Text(
            '$count',
            style: AppTypography.caption5.copyWith(
              color: Colors.white,
              height: 1,
            ),
          ),
        );
    }
  }
}
