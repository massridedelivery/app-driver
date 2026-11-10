import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_routes.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/theme/app_palette.dart';
import 'package:massdrive/features/document_registration/domain/document_reupload.dart';
import 'package:massdrive/features/document_registration/presentation/controllers/rejected_documents_provider.dart';

/// What home says about documents the admin sent back.
enum DocumentAlert { none, rejected, waiting }

/// Rejected wins: while any document is rejected the driver has something to
/// do. Once all were sent again they only wait for the review.
({DocumentAlert alert, int rejected}) documentAlertOf(List<ReuploadItem> open) {
  final rejected = open.where((d) => d.state == ReuploadState.rejected).length;
  if (rejected > 0) return (alert: DocumentAlert.rejected, rejected: rejected);
  if (open.isNotEmpty) return (alert: DocumentAlert.waiting, rejected: 0);
  return (alert: DocumentAlert.none, rejected: 0);
}

/// Home's document alert, from GET /api/driver/documents (one row per type).
({DocumentAlert alert, int rejected}) watchDocumentAlert(WidgetRef ref) =>
    documentAlertOf(ref.watch(reuploadDocumentsProvider).value ?? const []);

/// The status card's second line while a document is open: red "มีเอกสาร
/// ต้องอัปโหลดใหม่ ›" or neutral "เอกสารรอตรวจสอบ ›". Taps open the checklist.
class DocumentAlertLine extends StatelessWidget {
  const DocumentAlertLine({super.key, required this.alert});

  final DocumentAlert alert;

  @override
  Widget build(BuildContext context) {
    final rejected = alert == DocumentAlert.rejected;
    final color = rejected
        ? AppColors.semanticErrorBgHigh
        : AppColors.foundationOrange500;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () =>
          context.push(AppRoutes.documentRegistrationChecklistNamedPage),
      child: Row(
        children: [
          Icon(
            rejected
                ? Icons.error_outline_rounded
                : Icons.hourglass_top_rounded,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              rejected ? 'มีเอกสารต้องอัปโหลดใหม่' : 'เอกสารรอตรวจสอบ',
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

/// On the profile menu icon: a red count of rejected documents, or a small
/// neutral dot while documents wait for review. Nothing otherwise.
class DocumentMenuBadge extends StatelessWidget {
  const DocumentMenuBadge({
    super.key,
    required this.alert,
    required this.rejected,
  });

  final DocumentAlert alert;
  final int rejected;

  @override
  Widget build(BuildContext context) {
    switch (alert) {
      case DocumentAlert.none:
        return const SizedBox.shrink();
      case DocumentAlert.waiting:
        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.foundationOrange500,
            border: Border.all(color: context.palette.bg, width: 1.5),
          ),
        );
      case DocumentAlert.rejected:
        return Container(
          constraints: const BoxConstraints(minWidth: 18),
          height: 18,
          padding: const EdgeInsets.symmetric(horizontal: 5),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.semanticErrorBgHigh,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: context.palette.bg, width: 1.5),
          ),
          child: Text(
            '$rejected',
            style: AppTypography.caption5.copyWith(
              color: Colors.white,
              height: 1,
            ),
          ),
        );
    }
  }
}
