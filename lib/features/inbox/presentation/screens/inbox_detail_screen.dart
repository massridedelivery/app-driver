import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_routes.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/theme/app_palette.dart';
import 'package:massdrive/core/utils/toast_util.dart';
import 'package:massdrive/features/inbox/domain/inbox_message.dart';
import 'package:massdrive/features/inbox/presentation/inbox_controller.dart';
import 'package:massdrive/features/inbox/presentation/inbox_strings.dart';
import 'package:url_launcher/url_launcher.dart';

/// One message in full: its time, title and body, the campaign's button
/// (quests or a web page) when it has one, and "ลบข้อความนี้".
class InboxDetailScreen extends ConsumerWidget {
  const InboxDetailScreen({super.key, required this.message});

  final InboxMessage message;

  Future<void> _follow(BuildContext context, InboxLink link) async {
    switch (link.kind) {
      case InboxLinkKind.quests:
        context.push(AppRoutes.questsNamedPage);
      case InboxLinkKind.web:
        final s = InboxStrings.of(context);
        try {
          final opened = await launchUrl(
            Uri.parse(link.url!),
            mode: LaunchMode.externalApplication,
          );
          if (!opened) ToastUtil.showErrorToast(s.actionFailed);
        } catch (_) {
          ToastUtil.showErrorToast(s.actionFailed);
        }
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final s = InboxStrings.of(context);
    final router = GoRouter.of(context);
    final ok = await ref.read(inboxControllerProvider.notifier).delete(message);
    if (!ok) {
      ToastUtil.showErrorToast(s.deleteFailed);
      return;
    }
    if (router.canPop()) router.pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = InboxStrings.of(context);
    final link = message.link;

    return Scaffold(
      backgroundColor: context.palette.bg,
      appBar: AppBar(
        backgroundColor: context.palette.bg,
        elevation: 0,
        iconTheme: IconThemeData(color: context.palette.textPrimary),
        title: Text(
          s.detailTitle,
          style: AppTypography.heading5.copyWith(
            color: context.palette.textPrimary,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.stamp(message.createdAt, DateTime.now()),
                    style: AppTypography.caption3.copyWith(
                      color: context.palette.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    message.title,
                    style: AppTypography.heading4.copyWith(
                      color: context.palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SelectableText(
                    message.body,
                    style: AppTypography.body2.copyWith(
                      color: context.palette.textSecondary,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            // Clear the Android nav bar (edge-to-edge).
            padding: EdgeInsets.fromLTRB(
              20,
              8,
              20,
              12 + MediaQuery.viewPaddingOf(context).bottom,
            ),
            child: Column(
              children: [
                if (link != null)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () => _follow(context, link),
                      icon: Icon(
                        link.kind == InboxLinkKind.quests
                            ? Icons.emoji_events_outlined
                            : Icons.open_in_new,
                        color: Colors.white,
                      ),
                      label: Text(
                        link.kind == InboxLinkKind.quests
                            ? s.openQuests
                            : s.openLink,
                        style: AppTypography.label1.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.foundationOrange600,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                      ),
                    ),
                  ),
                TextButton.icon(
                  onPressed: () => _delete(context, ref),
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.foundationRed600,
                    size: 20,
                  ),
                  label: Text(
                    s.deleteThis,
                    style: AppTypography.label2.copyWith(
                      color: AppColors.foundationRed600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
