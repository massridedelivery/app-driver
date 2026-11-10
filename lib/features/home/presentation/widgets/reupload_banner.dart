import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_routes.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/theme/app_palette.dart';
import 'package:massdrive/features/document_registration/domain/document_reupload.dart';
import 'package:massdrive/features/document_registration/presentation/controllers/rejected_documents_provider.dart';
import 'package:massdrive/features/home/presentation/widgets/home_card.dart';

/// Home, approved driver: documents the admin sent back. Red "มีเอกสาร
/// ต้องอัปโหลดใหม่" while any is rejected; once all were sent again, a neutral
/// "เอกสารรอตรวจสอบ" until they are reviewed; nothing after that. Taps open
/// the checklist, which lists them.
class ReuploadBanner extends ConsumerWidget {
  const ReuploadBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final open = ref.watch(reuploadDocumentsProvider).value ?? const [];
    final rejected = [
      for (final d in open)
        if (d.state == ReuploadState.rejected) d,
    ];
    final shown = rejected.isNotEmpty ? rejected : open;
    if (shown.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ReuploadBannerCard(
        documents: shown,
        waiting: rejected.isEmpty,
        onTap: () =>
            context.push(AppRoutes.documentRegistrationChecklistNamedPage),
      ),
    );
  }
}

@visibleForTesting
class ReuploadBannerCard extends StatelessWidget {
  const ReuploadBannerCard({
    super.key,
    required this.documents,
    required this.onTap,
    this.waiting = false,
  });

  final List<ReuploadItem> documents;

  /// All of them were sent again and wait for review: neutral, not red.
  final bool waiting;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = waiting
        ? AppColors.foundationOrange500
        : AppColors.semanticErrorBgHigh;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: HomeCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Icon(
              waiting ? Icons.hourglass_top_rounded : Icons.upload_file_rounded,
              size: 22,
              color: accent,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    waiting ? 'เอกสารรอตรวจสอบ' : 'มีเอกสารต้องอัปโหลดใหม่',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.label2.copyWith(color: accent),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    documents.map((d) => documentTitle(d.type)).join(', '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption5.copyWith(
                      color: context.palette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: context.palette.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
