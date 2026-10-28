import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:massdrive/features/call/domain/call_callability.dart';
import 'package:massdrive/features/call/domain/call_error.dart';
import 'package:massdrive/features/call/domain/call_kind.dart';
import 'package:massdrive/features/call/presentation/call_permissions.dart';
import 'package:massdrive/features/call/presentation/controllers/call_availability.dart';
import 'package:massdrive/features/call/presentation/controllers/call_controller.dart';
import 'package:permission_handler/permission_handler.dart';

/// The in-app "call the customer" action of an order, drawn by [builder] in
/// the screen's own button style. Nothing shows while calling is off, the
/// order isn't callable in [status], or the backend refused it for this
/// order. No phone number is involved anywhere.
class CallCustomerButton extends ConsumerWidget {
  const CallCustomerButton({
    super.key,
    required this.kind,
    required this.jobId,
    required this.builder,
    this.status,
    this.finishedAt,
    this.customerName = '',
  });

  final CallKind kind;
  final String jobId;

  /// The order's status; null when the screen doesn't know it (the chat) —
  /// then the backend decides.
  final String? status;

  /// Completion / delivery time, for the 24h window after the order.
  final DateTime? finishedAt;
  final String customerName;
  final Widget Function(BuildContext context, VoidCallback onCall) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allowed = ref.watch(
      callAvailabilityProvider.select((s) => s.canCall(jobId)),
    );
    final callable =
        status == null ||
        isOrderCallable(kind, status!, finishedAt: finishedAt);
    if (!allowed || !callable) return const SizedBox.shrink();
    return builder(context, () => _call(context, ref));
  }

  Future<void> _call(BuildContext context, WidgetRef ref) async {
    // Read up front: the button may be gone by the time the request returns.
    final controller = ref.read(callControllerProvider.notifier);
    final availability = ref.read(callAvailabilityProvider.notifier);
    void snack(String text) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }

    if (!await requestCallAudioPermissions()) {
      snack('กรุณาอนุญาตให้ใช้ไมโครโฟนในการตั้งค่า เพื่อโทรหาลูกค้า');
      if (await Permission.microphone.isPermanentlyDenied) {
        await openAppSettings();
      }
      return;
    }
    try {
      await controller.startCall(kind, jobId, peerName: customerName);
    } on CallError catch (e) {
      final outcome = callErrorOutcome(e);
      if (outcome.hideButton) availability.hideFor(jobId);
      if (outcome.refreshSettings) unawaited(availability.refresh());
      snack(outcome.message);
    }
  }
}
