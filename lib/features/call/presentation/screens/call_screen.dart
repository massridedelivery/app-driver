import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/theme/app_palette.dart';
import 'package:massdrive/features/call/domain/call_models.dart';
import 'package:massdrive/features/call/domain/call_state.dart';
import 'package:massdrive/features/call/presentation/controllers/call_controller.dart';
import 'package:massdrive/features/chat/presentation/screens/chat_screen.dart';

/// The in-call screen: the customer's name and photo, the call's progress
/// (ringing, timer, reconnecting), mute / speaker / hang-up. Once the call
/// ends it says why — and when the customer didn't pick up, offers the
/// order's chat. Opened by the app-root call listener.
class CallScreen extends ConsumerStatefulWidget {
  const CallScreen({super.key, required this.onDisposed});

  /// Lets the listener reopen the screen if a navigation removed it while
  /// the call is still on.
  final VoidCallback onDisposed;

  @override
  ConsumerState<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends ConsumerState<CallScreen> {
  Timer? _ticker;
  Timer? _autoClose;

  @override
  void initState() {
    super.initState();
    // Repaints the call timer.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _autoClose?.cancel();
    widget.onDisposed();
    super.dispose();
  }

  void _close() {
    if (mounted) Navigator.of(context).maybePop();
  }

  void _openChat(CallInfo call) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => ChatScreen(
          jobId: call.jobId,
          passengerName: call.displayName,
          vertical: call.kind.chatVertical,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<CallState>(callControllerProvider, (prev, next) {
      if (next.phase == CallPhase.idle) _close();
      // Nothing to choose after a plain hang-up: close on its own.
      if (next.phase == CallPhase.ended &&
          prev?.phase != CallPhase.ended &&
          !(next.endReason?.suggestsChat ?? false)) {
        _autoClose = Timer(const Duration(seconds: 2), _close);
      }
    });
    final s = ref.watch(callControllerProvider);
    final call = s.call;
    final p = context.palette;

    return PopScope(
      // While the call is on, leaving is by hanging up.
      canPop: !s.isBusy,
      child: Scaffold(
        backgroundColor: p.bg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
            // Full width, so everything stays centred even when nothing below
            // the name is as wide as the screen (the "ปิด"-only ended state).
            child: SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  _Avatar(url: call?.peerAvatar ?? ''),
                  const SizedBox(height: 20),
                  Text(
                    call?.displayName ?? 'ลูกค้า',
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.heading3.copyWith(
                      color: p.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _statusLine(s),
                    textAlign: TextAlign.center,
                    style: AppTypography.body2.copyWith(
                      color: s.phase == CallPhase.reconnecting
                          ? AppColors.foundationOrange600
                          : p.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  if (s.phase == CallPhase.ended)
                    _EndedActions(
                      suggestChat: s.endReason?.suggestsChat ?? false,
                      onChat: call == null ? null : () => _openChat(call),
                      onClose: _close,
                    )
                  else
                    _Controls(state: s),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _statusLine(CallState s) => switch (s.phase) {
    CallPhase.outgoingRinging => 'กำลังโทรหาลูกค้า…',
    CallPhase.incomingRinging || CallPhase.connecting => 'กำลังเชื่อมต่อ…',
    CallPhase.connected => _elapsed(s.connectedAt),
    CallPhase.reconnecting => 'กำลังเชื่อมต่อใหม่…',
    CallPhase.ended => s.endReason?.message ?? CallEndReason.hangup.message,
    CallPhase.idle => '',
  };

  String _elapsed(DateTime? since) {
    if (since == null) return '00:00';
    final d = DateTime.now().difference(since);
    String two(int n) => n.toString().padLeft(2, '0');
    final mm = two(d.inMinutes.remainder(60));
    final ss = two(d.inSeconds.remainder(60));
    return d.inHours > 0 ? '${d.inHours}:$mm:$ss' : '$mm:$ss';
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 56,
      backgroundColor: AppColors.foundationOrange700,
      foregroundImage: url.isEmpty ? null : CachedNetworkImageProvider(url),
      child: const Icon(Icons.person, size: 56, color: Colors.white),
    );
  }
}

class _Controls extends ConsumerWidget {
  const _Controls({required this.state});

  final CallState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(callControllerProvider.notifier);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _RoundToggle(
              icon: state.muted ? Icons.mic_off : Icons.mic_none,
              label: 'ปิดเสียง',
              active: state.muted,
              onTap: controller.toggleMute,
            ),
            _RoundToggle(
              icon: Icons.volume_up_outlined,
              label: 'ลำโพง',
              active: state.speakerOn,
              onTap: controller.toggleSpeaker,
            ),
          ],
        ),
        const SizedBox(height: 32),
        Semantics(
          button: true,
          label: 'วางสาย',
          child: GestureDetector(
            onTap: controller.hangUp,
            child: Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.semanticErrorBgHigh,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.call_end, color: Colors.white, size: 32),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'วางสาย',
          style: AppTypography.caption4.copyWith(
            color: context.palette.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _RoundToggle extends StatelessWidget {
  const _RoundToggle({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      children: [
        Material(
          color: active ? p.textPrimary : p.surfaceAlt,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 64,
              height: 64,
              child: Icon(icon, color: active ? p.bg : p.textPrimary),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: AppTypography.caption4.copyWith(color: p.textSecondary),
        ),
      ],
    );
  }
}

class _EndedActions extends StatelessWidget {
  const _EndedActions({
    required this.suggestChat,
    required this.onChat,
    required this.onClose,
  });

  final bool suggestChat;
  final VoidCallback? onChat;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      children: [
        if (suggestChat) ...[
          Text(
            'ลองส่งแชทหาลูกค้าแทนไหม?',
            style: AppTypography.body2.copyWith(color: p.textSecondary),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: onChat,
              icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
              label: Text(
                'แชทกับลูกค้า',
                style: AppTypography.heading6.copyWith(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.foundationOrange700,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextButton(
          onPressed: onClose,
          child: Text(
            'ปิด',
            style: AppTypography.label2.copyWith(color: p.textSecondary),
          ),
        ),
      ],
    );
  }
}
