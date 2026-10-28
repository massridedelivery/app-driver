import 'package:massdrive/features/call/domain/call_kind.dart';

/// Order statuses during which the driver and the customer can call.
const Map<CallKind, Set<String>> _activeStatuses = {
  CallKind.ride: {'ACCEPTED', 'ARRIVED_AT_PICK_UP', 'PICKED_UP'},
  CallKind.food: {'DRIVER_ASSIGNED', 'DRIVER_PICKED_UP'},
  // Messenger spells it ARRIVED_AT_PICKUP (no middle underscore).
  CallKind.messenger: {'ACCEPTED', 'ARRIVED_AT_PICKUP', 'PICKED_UP'},
};

/// The finished status after which calling stays open for [callWindowAfterEnd].
const Map<CallKind, String> _finishedStatus = {
  CallKind.ride: 'COMPLETED',
  CallKind.food: 'DELIVERED',
  CallKind.messenger: 'DELIVERED',
};

const Duration callWindowAfterEnd = Duration(hours: 24);

/// Whether an order in [status] can be called (the backend's rule, so the
/// button isn't offered only to be refused): while it runs, and for 24h after
/// it is done — [finishedAt] is the completion / delivery time; without one a
/// finished order isn't offered.
bool isOrderCallable(
  CallKind kind,
  String status, {
  DateTime? finishedAt,
  DateTime? now,
}) {
  final s = status.toUpperCase();
  if (_activeStatuses[kind]!.contains(s)) return true;
  if (s != _finishedStatus[kind] || finishedAt == null) return false;
  final since = (now ?? DateTime.now()).difference(finishedAt);
  return since < callWindowAfterEnd;
}
