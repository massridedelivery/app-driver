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

/// กล่องข้อความ: the driver's campaigns and in-app messages, newest first,
/// grouped by day. Swipe a card to delete it; the app bar has "อ่านทั้งหมด"
/// (only while something is unread) and "ลบทั้งหมด" (always confirmed).
class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  final _scroll = ScrollController();

  InboxController get _inbox => ref.read(inboxControllerProvider.notifier);

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _inbox.refresh());
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.extentAfter < 400) _inbox.loadMore();
  }

  Future<void> _readAll(InboxStrings s) async {
    if (!await _inbox.readAll()) ToastUtil.showErrorToast(s.actionFailed);
  }

  Future<void> _deleteAll(InboxStrings s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: dialogContext.palette.surface,
        icon: const Icon(
          Icons.delete_outline,
          color: AppColors.foundationRed600,
          size: 36,
        ),
        title: Text(
          s.deleteAllTitle,
          textAlign: TextAlign.center,
          style: AppTypography.heading5.copyWith(
            color: dialogContext.palette.textPrimary,
          ),
        ),
        content: Text(
          s.deleteAllBody,
          textAlign: TextAlign.center,
          style: AppTypography.caption3.copyWith(
            color: dialogContext.palette.textSecondary,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              s.cancel,
              style: AppTypography.caption3.copyWith(
                color: dialogContext.palette.textTertiary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.foundationRed600,
              elevation: 0,
            ),
            child: Text(
              s.deleteAllConfirm,
              style: AppTypography.caption3.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    if (!await _inbox.deleteAll()) ToastUtil.showErrorToast(s.actionFailed);
  }

  Future<void> _delete(InboxMessage m, InboxStrings s) async {
    if (!await _inbox.delete(m)) ToastUtil.showErrorToast(s.deleteFailed);
  }

  void _open(InboxMessage m) {
    _inbox.markRead(m);
    context.push(AppRoutes.inboxDetailNamedPage, extra: m);
  }

  @override
  Widget build(BuildContext context) {
    final s = InboxStrings.of(context);
    final state = ref.watch(inboxControllerProvider);

    return Scaffold(
      backgroundColor: context.palette.bg,
      appBar: AppBar(
        backgroundColor: context.palette.bg,
        elevation: 0,
        iconTheme: IconThemeData(color: context.palette.textPrimary),
        title: Text(
          s.title,
          style: AppTypography.heading5.copyWith(
            color: context.palette.textPrimary,
          ),
        ),
        actions: [
          if (state.unreadCount > 0)
            TextButton(
              onPressed: () => _readAll(s),
              child: Text(
                s.readAll,
                style: AppTypography.label2.copyWith(
                  color: AppColors.foundationOrange600,
                ),
              ),
            ),
          if (state.items.isNotEmpty)
            IconButton(
              tooltip: s.deleteAllTooltip,
              icon: Icon(
                Icons.delete_outline,
                color: context.palette.textSecondary,
              ),
              onPressed: () => _deleteAll(s),
            ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.foundationOrange600,
        onRefresh: _inbox.refresh,
        child: _body(context, state, s),
      ),
    );
  }

  Widget _body(BuildContext context, InboxState state, InboxStrings s) {
    if (!state.loaded) {
      if (state.failed) {
        return _Centered(
          icon: Icons.cloud_off_outlined,
          title: s.loadFailed,
          action: TextButton(
            onPressed: _inbox.refresh,
            child: Text(
              s.retry,
              style: AppTypography.label2.copyWith(
                color: AppColors.foundationOrange600,
              ),
            ),
          ),
        );
      }
      return const Center(
        child: CircularProgressIndicator(color: AppColors.foundationOrange600),
      );
    }
    if (state.isEmpty) {
      return _Centered(
        icon: Icons.drafts_outlined,
        title: s.emptyTitle,
        body: s.emptyBody,
      );
    }

    final now = DateTime.now();
    final rows = <Widget>[];
    String? lastDay;
    for (final m in state.items) {
      final day = s.day(m.createdAt, now);
      if (day != lastDay) {
        rows.add(_DayHeader(day));
        lastDay = day;
      }
      rows.add(
        _SwipeToDelete(
          key: ValueKey(m.id),
          label: s.delete,
          onDismissed: () => _delete(m, s),
          child: _MessageCard(
            message: m,
            time: s.time(m.createdAt),
            onTap: () => _open(m),
          ),
        ),
      );
    }
    if (state.loadingMore) {
      rows.add(
        const Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: CircularProgressIndicator(
              color: AppColors.foundationOrange600,
            ),
          ),
        ),
      );
    }

    return ListView(
      controller: _scroll,
      physics: const AlwaysScrollableScrollPhysics(),
      // Clear the Android nav bar (edge-to-edge) under the last card.
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      children: rows,
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
    child: Text(
      label,
      style: AppTypography.caption4.copyWith(
        color: context.palette.textTertiary,
      ),
    ),
  );
}

class _SwipeToDelete extends StatelessWidget {
  const _SwipeToDelete({
    super.key,
    required this.label,
    required this.onDismissed,
    required this.child,
  });

  final String label;
  final VoidCallback onDismissed;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Dismissible(
        key: key!,
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onDismissed(),
        background: Container(
          color: AppColors.foundationRed600,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.delete_outline, color: Colors.white),
              const SizedBox(height: 2),
              Text(
                label,
                style: AppTypography.caption4.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
        child: child,
      ),
    ),
  );
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.message,
    required this.time,
    required this.onTap,
  });

  final InboxMessage message;
  final String time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unread = !message.isRead;
    return Material(
      color: context.palette.surface,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: unread
                        ? AppColors.foundationOrange600
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style:
                          (unread
                                  ? AppTypography.label1
                                  : AppTypography.caption3)
                              .copyWith(
                                color: unread
                                    ? context.palette.textPrimary
                                    : context.palette.textSecondary,
                              ),
                    ),
                    if (message.body.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        message.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body2.copyWith(
                          color: unread
                              ? context.palette.textSecondary
                              : context.palette.textTertiary,
                          height: 1.45,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      time,
                      style: AppTypography.caption5.copyWith(
                        color: context.palette.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Empty / failed states. Scrollable so pull-to-refresh still works.
class _Centered extends StatelessWidget {
  const _Centered({
    required this.icon,
    required this.title,
    this.body,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? body;
  final Widget? action;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: box.maxHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: context.palette.surface,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 40,
                  color: context.palette.textTertiary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTypography.heading5.copyWith(
                  color: context.palette.textPrimary,
                ),
              ),
              if (body != null) ...[
                const SizedBox(height: 8),
                Text(
                  body!,
                  textAlign: TextAlign.center,
                  style: AppTypography.caption3.copyWith(
                    color: context.palette.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
              if (action != null) ...[const SizedBox(height: 12), action!],
            ],
          ),
        ),
      ),
    ),
  );
}
