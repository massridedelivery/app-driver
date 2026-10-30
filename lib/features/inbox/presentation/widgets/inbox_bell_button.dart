import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_routes.dart';
import 'package:massdrive/core/theme/app_palette.dart';
import 'package:massdrive/features/inbox/presentation/inbox_controller.dart';
import 'package:massdrive/features/inbox/presentation/inbox_strings.dart';

/// The bell on the home map (above settings) with the unread badge. Refreshes
/// the count when home opens, when the app comes back, and after the inbox
/// closes.
class InboxBellButton extends ConsumerStatefulWidget {
  const InboxBellButton({super.key});

  @override
  ConsumerState<InboxBellButton> createState() => _InboxBellButtonState();
}

class _InboxBellButtonState extends ConsumerState<InboxBellButton>
    with WidgetsBindingObserver {
  InboxController get _inbox => ref.read(inboxControllerProvider.notifier);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _inbox.refreshUnread());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _inbox.refreshUnread();
  }

  Future<void> _open() async {
    await context.push(AppRoutes.inboxNamedPage);
    if (mounted) _inbox.refreshUnread();
  }

  @override
  Widget build(BuildContext context) {
    final unread = ref.watch(
      inboxControllerProvider.select((s) => s.unreadCount),
    );
    return Semantics(
      button: true,
      label: InboxStrings.of(context).title,
      child: GestureDetector(
        onTap: _open,
        child: SizedBox(
          width: 50,
          height: 50,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: context.palette.bg.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              if (unread > 0)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 20),
                    height: 20,
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.foundationOrange600,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Text(
                      unread > 99 ? '99+' : '$unread',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
