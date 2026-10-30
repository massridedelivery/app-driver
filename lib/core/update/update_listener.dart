import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:massdrive/core/update/suggest_update_dialog.dart';
import 'package:massdrive/core/update/update_check.dart';
import 'package:massdrive/features/call/presentation/controllers/call_controller.dart';
import 'package:massdrive/router/app_routes.dart';

/// App-root driver of [UpdateCheck]: checks on cold start and on resume (when
/// the last check is over 6 h old), and shows a pending "update available"
/// dialog once the driver is somewhere it won't get in the way — not on the
/// splash, an offer, a live job or a call.
class UpdateListener extends ConsumerStatefulWidget {
  const UpdateListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<UpdateListener> createState() => _UpdateListenerState();
}

class _UpdateListenerState extends ConsumerState<UpdateListener>
    with WidgetsBindingObserver {
  final _check = UpdateCheck.instance;
  bool _dialogOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AppRouter.isInCall = () => ref.read(callControllerProvider).hasScreen;
    _check.suggestion.addListener(_scheduleSuggestion);
    AppRouter.router.routerDelegate.addListener(_scheduleSuggestion);
    _check.check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _check.suggestion.removeListener(_scheduleSuggestion);
    AppRouter.router.routerDelegate.removeListener(_scheduleSuggestion);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check.checkIfStale();
  }

  // Route changes notify mid-navigation; open the dialog after the frame.
  void _scheduleSuggestion() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _maybeShowSuggestion();
    });
  }

  void _maybeShowSuggestion() {
    final prompt = _check.suggestion.value;
    if (prompt == null || _dialogOpen || _check.forced != null) return;
    if (!AppRouter.isQuietMoment) return;
    final ctx = AppRouter.rootContext;
    if (ctx == null || !ctx.mounted) return;
    _dialogOpen = true;
    _check.markSuggestionShown(prompt);
    showSuggestUpdateDialog(ctx, prompt).whenComplete(() {
      _dialogOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // A forced update waits for the call to end; then it can take over, and a
    // held-back suggestion can show.
    ref.listen(callControllerProvider.select((s) => s.hasScreen), (
      wasInCall,
      inCall,
    ) {
      if (wasInCall == true && !inCall) {
        _check.reapply();
        _scheduleSuggestion();
      }
    });
    return widget.child;
  }
}
