import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:massdrive/core/models/socket_message_model.dart';
import 'package:massdrive/core/services/socket_service.dart';
import 'package:massdrive/features/call/domain/call_ports.dart';

/// [CallTransport] over the app's single [SocketService].
class SocketCallTransport implements CallTransport {
  SocketCallTransport(this._socket, {required bool Function() isOnline})
    : _isOnline = isOnline;

  final SocketService _socket;
  final bool Function() _isOnline;

  /// The socket was down when the call needed it (the driver is offline) —
  /// [release] closes it again.
  bool _openedForCall = false;

  @override
  Stream<SocketMessageModel> get messages => _socket.messages;

  @override
  Stream<bool> get connectionStatus => _socket.onConnectionStatus;

  @override
  Stream<void> get networkChanges => Connectivity().onConnectivityChanged;

  @override
  bool get isConnected => _socket.isConnected;

  @override
  Future<void> ensureConnected() async {
    if (_socket.isConnected) return;
    _openedForCall = true;
    await _socket.connect();
    // connect() returns at once when another caller is already connecting.
    if (!_socket.isConnected) {
      await _socket.onConnectionStatus
          .firstWhere((up) => up)
          .timeout(const Duration(seconds: 10), onTimeout: () => false);
    }
  }

  @override
  void release() {
    if (!_openedForCall) return;
    _openedForCall = false;
    // Went online during the call: the socket is the online session's now.
    if (!_isOnline()) _socket.disconnect();
  }

  /// `{"type":"call_signal","call_id":…,"kind":…,"payload":…}`, fields at
  /// the frame root.
  @override
  void sendSignal(String callId, String kind, Map<String, dynamic> payload) {
    _socket.sendMessage('call_signal', {
      '_merge_to_root': true,
      'call_id': callId,
      'kind': kind,
      'payload': payload,
    });
  }
}
