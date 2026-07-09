import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:massdrive/core/constants/endpoints.dart';
import 'package:massdrive/core/data/secure_storage/secure_storage_key.dart';
import 'package:massdrive/core/data/secure_storage/secure_storage_manager.dart';
import 'package:massdrive/core/models/socket_message_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

part 'socket_service.g.dart';

@Riverpod(keepAlive: true)
SocketService socketService(ref) {
  final service = SocketService();
  ref.onDispose(() => service.disconnect());
  return service;
}

class SocketService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;

  /// Socket-level ping/pong keep-alive: detects half-open (silently dead)
  /// connections and closes them → onDone → reconnect.
  static const Duration _pingInterval = Duration(seconds: 15);

  /// Reconnect backoff is capped so a driver never stops trying to reconnect.
  static const int _maxBackoffSeconds = 30;

  int _reconnectAttempts = 0;

  /// True only once the handshake completed (`ready`). `_channel != null` is
  /// set before that, so it must NOT be used as the connected signal.
  bool _isReady = false;
  bool _connecting = false;

  /// Set by an intentional [disconnect]; suppresses auto-reconnect.
  bool _intentionalClose = false;

  final StreamController<SocketMessageModel> _messageController =
      StreamController<SocketMessageModel>.broadcast();

  final StreamController<bool> _connectionStatusController =
      StreamController<bool>.broadcast();

  Stream<SocketMessageModel> get messages => _messageController.stream;

  Stream<bool> get onConnectionStatus => _connectionStatusController.stream;

  bool get isConnected => _isReady;

  String _buildWebSocketUrl(String token) {
    // Hardcoding development URL to match AuthApiServiceImpl and avoid EnvironmentConfig issues
    const baseUrl = 'wss://driver-api-dev.nutchaphut.dev';

    // Ensure token is clean of whitespace/newlines
    final cleanToken = token.trim();

    // Build full URL and ensure NO trailing characters
    final url = '$baseUrl${Endpoints.websocketPath}?token=$cleanToken';
    return url;
  }

  Future<void> connect() async {
    if (_isReady || _connecting) return;

    _connecting = true;
    _intentionalClose = false;
    _reconnectTimer?.cancel();

    try {
      if (kDebugMode) debugPrint('SocketService: Starting connection steps...');

      final secureStorage = SecureStorageManager();
      final token = await secureStorage.read(SecureStorageKey.accessToken);

      if (token == null || token.isEmpty) {
        if (kDebugMode) debugPrint('SocketService: No access token found. Cannot connect.');
        _connecting = false;
        return;
      }

      final url = _buildWebSocketUrl(token);
      if (kDebugMode) debugPrint('SocketService: Connecting to $url');

      // IOWebSocketChannel gives us socket-level ping/pong so a dead TCP
      // connection is detected and closed instead of appearing "connected".
      final channel = IOWebSocketChannel.connect(
        Uri.parse(url),
        pingInterval: _pingInterval,
      );
      _channel = channel;

      await channel.ready;
      if (kDebugMode) debugPrint('✅ SocketService: Connected successfully to the backend.');

      _isReady = true;
      _connecting = false;
      _reconnectAttempts = 0;
      _connectionStatusController.add(true);

      _subscription = channel.stream.listen(
        (data) {
          if (kDebugMode) debugPrint('📥 SocketService Received Data: $data');
          try {
            final jsonMap = jsonDecode(data.toString());
            final message = SocketMessageModel.fromJson(jsonMap);
            _messageController.add(message);
          } catch (e) {
            if (kDebugMode) debugPrint('⚠️ SocketService Parse Error: $e - Data: $data');
          }
        },
        onError: (error) {
          if (kDebugMode) debugPrint('SocketService WebSocket Error: $error');
          _handleDisconnect();
        },
        onDone: () {
          if (kDebugMode) debugPrint('SocketService WebSocket Closed');
          _handleDisconnect();
        },
        cancelOnError: true,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('SocketService Connection Error: $e');
      _connecting = false;
      _handleDisconnect();
    }
  }

  /// Tears down the current channel and (unless [disconnect] was called)
  /// schedules a capped-backoff reconnect — indefinitely, so a temporary
  /// network drop never permanently kills the socket.
  void _handleDisconnect() {
    // Already torn down and a reconnect is pending → nothing to do.
    if (_channel == null && _reconnectTimer != null) return;

    final wasReady = _isReady;
    _cleanupChannel();
    if (wasReady) _connectionStatusController.add(false);

    if (_intentionalClose) return;

    _reconnectAttempts++;
    final delay = _backoffSeconds(_reconnectAttempts);
    if (kDebugMode) {
      debugPrint('SocketService: Reconnecting in ${delay}s (attempt $_reconnectAttempts)');
    }
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: delay), connect);
  }

  /// Exponential backoff (2,4,8,16,…) capped at [_maxBackoffSeconds].
  int _backoffSeconds(int attempt) {
    final seconds = 1 << attempt.clamp(1, 5); // 2..32
    return seconds > _maxBackoffSeconds ? _maxBackoffSeconds : seconds;
  }

  void _cleanupChannel() {
    _isReady = false;
    _connecting = false;
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;
  }

  void sendMessage(String type, [Map<String, dynamic>? data]) {
    if (!_isReady || _channel == null) {
      if (kDebugMode) {
        debugPrint('SocketService Warning: Cannot send "$type", socket not ready.');
      }
      return;
    }

    final Map<String, dynamic> payload = {
      'type': type,
      if (data != null) 'data': data,
    };

    // Some simple messages (e.g. location_update) put lat/lng at the payload
    // root per the WS guide — support both shapes.
    if (data != null && data.containsKey('_merge_to_root')) {
      data.remove('_merge_to_root');
      payload.addAll(data);
      payload.remove('data');
    }

    final jsonStr = jsonEncode(payload);
    try {
      _channel!.sink.add(jsonStr);
      if (kDebugMode) debugPrint('SocketService Sent: $jsonStr');
    } catch (e) {
      if (kDebugMode) debugPrint('SocketService: send failed ($type) → $e');
      _handleDisconnect();
    }
  }

  // MARK: - Specific Actions

  void sendLocationUpdate(double lat, double lng) {
    sendMessage('location_update', {
      '_merge_to_root': true,
      'lat': lat,
      'lng': lng,
    });
  }

  void acceptJob(String jobId) {
    sendMessage('accept_job', {'_merge_to_root': true, 'job_id': jobId});
  }

  void rejectJob(String jobId) {
    sendMessage('reject_job', {'_merge_to_root': true, 'job_id': jobId});
  }

  void updateJobStatus(String jobId, String status) {
    sendMessage('job_status', {
      '_merge_to_root': true,
      'job_id': jobId,
      'status': status,
    });
  }

  /// Intentional close (logout, job finished, provider dispose). Suppresses
  /// auto-reconnect until [connect] is called again.
  void disconnect() {
    _intentionalClose = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempts = 0;
    _cleanupChannel();
  }
}
