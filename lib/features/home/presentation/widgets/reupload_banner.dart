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

/// Home, approved driver: documents the admin sent back for a re-upload.
/// Nothing when there are none. Taps open the checklist, which lists them.
class ReuploadBanner extends ConsumerWidget {
  const ReuploadBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rejected = ref.watch(rejectedDocumentsProvider).value ?? const [];
    if (rejected.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ReuploadBannerCard(
        rejected: rejected,
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
    required this.rejected,
    required this.onTap,
  });

  final List<RejectedDocument> rejected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: HomeCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            const Icon(
              Icons.upload_file_rounded,
              size: 22,
              color: AppColors.semanticErrorBgHigh,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'มีเอกสารต้องอัปโหลดใหม่',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.label2.copyWith(
                      color: AppColors.semanticErrorBgHigh,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    rejectedNames(rejected),
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
