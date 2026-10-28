import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:massdrive/features/call/domain/call_state.dart';
import 'package:massdrive/features/call/presentation/controllers/call_availability.dart';
import 'package:massdrive/features/call/presentation/controllers/call_controller.dart';
import 'package:massdrive/features/call/presentation/screens/call_screen.dart';
import 'package:massdrive/router/app_routes.dart';

/// App-root listener for in-app calls: keeps the call controller and the
/// calling settings alive from launch (so a call that woke the app is picked
/// up), and opens the call screen over whatever is showing once a call is
/// placed or answered.
class CallListener extends ConsumerStatefulWidget {
  const CallListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<CallListener> createState() => _CallListenerState();
}

class _CallListenerState extends ConsumerState<CallListener>
    with WidgetsBindingObserver {
  bool _screenOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The settings fetch at launch may have run offline.
    if (state == AppLifecycleState.resumed &&
        !ref.read(callAvailabilityProvider).enabled) {
      ref.read(callAvailabilityProvider.notifier).refresh();
    }
  }

  void _openScreen([int tries = 0]) {
    if (_screenOpen || !ref.read(callControllerProvider).hasScreen) return;
    final ctx = AppRouter.rootContext;
    if (ctx == null || !ctx.mounted) {
      // Cold start (answered on the lock screen): the router isn't up yet.
      if (tries < 20) {
        Future.delayed(
          const Duration(milliseconds: 250),
          () => _openScreen(tries + 1),
        );
      }
      return;
    }
    _screenOpen = true;
    Navigator.of(ctx).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => CallScreen(onDisposed: _onScreenGone),
      ),
    );
  }

  void _onScreenGone() {
    _screenOpen = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final s = ref.read(callControllerProvider);
      if (s.phase == CallPhase.ended) {
        ref.read(callControllerProvider.notifier).dismiss();
      } else if (s.hasScreen) {
        // A navigation (e.g. splash → home) took the screen away mid-call.
        _openScreen();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(callAvailabilityProvider, (_, _) {});
    ref.listen<CallState>(callControllerProvider, (prev, next) {
      if (next.hasScreen && next.phase != CallPhase.ended) _openScreen();
    });
    return widget.child;
  }
}
