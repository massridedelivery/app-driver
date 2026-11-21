import 'dart:async';

import 'package:flutter/foundation.dart';

/// The back office forced a parcel's status (BE fee29aed): the WS frame
/// `messenger_status_updated` `{order_id, status}`, mirrored by a push of the
/// same `data.type`. Only the back office sends it; the driver's own steps
/// never do.
class MessengerStatusOverride {
  const MessengerStatusOverride(this.orderId, this.status);

  final String orderId;

  /// Upper-case, e.g. CANCELLED, DELIVERED, PICKED_UP.
  final String status;

  /// The order is over for the driver, who is back in dispatch.
  bool get ended => status == 'CANCELLED' || status == 'DELIVERED';
}

const messengerStatusOverrideType = 'messenger_status_updated';

/// The override in a WS frame or push data (fields top-level or under
/// `data`); null for anything else.
MessengerStatusOverride? messengerStatusOverrideOf(
  String? type,
  Map<String, dynamic> raw, [
  Map<String, dynamic>? data,
]) {
  if (type != messengerStatusOverrideType) return null;
  Object? read(String k) => raw[k] ?? data?[k];
  final id = read('order_id')?.toString();
  final status = read('status')?.toString().toUpperCase();
  if (id == null || id.isEmpty || status == null || status.isEmpty) {
    return null;
  }
  return MessengerStatusOverride(id, status);
}

/// What the driver reads when the back office ends the parcel they're on.
String messengerOverrideEndedMessage(String status) => status == 'DELIVERED'
    ? 'ผู้ดูแลระบบปิดงานส่งพัสดุนี้แล้ว คุณรับงานใหม่ได้ตามปกติ'
    : 'ผู้ดูแลระบบยกเลิกงานส่งพัสดุนี้แล้ว คุณรับงานใหม่ได้ตามปกติ';

/// App-wide channel for overrides from the push (the WS frame reports here
/// too), so the messenger controller hears both once.
class MessengerStatusOverrides {
  MessengerStatusOverrides._();
  static final MessengerStatusOverrides instance = MessengerStatusOverrides._();

  final _events = StreamController<MessengerStatusOverride>.broadcast();
  final _seen = <String>{};

  Stream<MessengerStatusOverride> get events => _events.stream;

  void report(MessengerStatusOverride o) {
    if (!_seen.add('${o.orderId}:${o.status}')) return;
    _events.add(o);
  }

  @visibleForTesting
  void debugReset() => _seen.clear();
}
