import 'dart:async';

/// Push `type`s that belong to in-app calling.
const callPushTypes = {'call_incoming', 'call_ended'};

bool isCallPush(Map<String, dynamic> data) =>
    callPushTypes.contains(data['type']?.toString());

/// App-wide channel for call pushes (`call_incoming` / `call_ended` FCM data)
/// the app gets while running; the call controller listens.
class CallPushes {
  CallPushes._();
  static final CallPushes instance = CallPushes._();

  final _pushes = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get pushes => _pushes.stream;

  void report(Map<String, dynamic> data) => _pushes.add(data);
}
