import 'dart:async';
import 'dart:convert';
import 'package:massdrive/core/configs/environment_config.dart';
import 'package:massdrive/core/constants/endpoints.dart';
import 'package:massdrive/core/data/secure_storage/secure_storage_key.dart';
import 'package:massdrive/core/data/secure_storage/secure_storage_manager.dart';
import 'package:massdrive/core/models/socket_message_model.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter/foundation.dart';

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
  Timer? _heartbeatTimer;
  
  // Reconnect settings
  int _reconnectAttempts = 0;
  final int _maxReconnectAttempts = 5;

  final StreamController<SocketMessageModel> _messageController = 
      StreamController<SocketMessageModel>.broadcast();
  Stream<SocketMessageModel> get messages => _messageController.stream;
  
  bool get isConnected => _channel != null;

  String _buildWebSocketUrl(String token) {
    var baseUrl = EnvironmentConfig.apiUrl;
    // Replace http/https with ws/wss
    baseUrl = baseUrl.replaceFirst('http://', 'ws://').replaceFirst('https://', 'wss://');
    
    // In case apiUrl is just a domain like 'https://driver-api.nutchaphut.dev'
    if (!baseUrl.startsWith('ws')) {
      baseUrl = 'wss://$baseUrl';
    }
    
    // E.g., wss://driver-api.nutchaphut.dev/ws?token=ABC
    return '$baseUrl${Endpoints.websocketPath}?token=$token';
  }

  Future<void> connect() async {
    if (_channel != null) return;
    
    _reconnectTimer?.cancel();

    try {
      final secureStorage = SecureStorageManager();
      final token = await secureStorage.read(SecureStorageKey.accessToken);
      
      if (token == null || token.isEmpty) {
        debugPrint('SocketService: No access token found. Cannot connect.');
        return;
      }

      final url = _buildWebSocketUrl(token);
      debugPrint('SocketService: Connecting to $url');
      
      _channel = WebSocketChannel.connect(Uri.parse(url));
      _reconnectAttempts = 0; // Reset on successful init
      _startHeartbeat();
      
      _subscription = _channel!.stream.listen(
        (data) {
          try {
            final jsonMap = jsonDecode(data.toString());
            final message = SocketMessageModel.fromJson(jsonMap);
            _messageController.add(message);
          } catch (e) {
            debugPrint('SocketService Parse Error: $e - Data: $data');
          }
        },
        onError: (error) {
          debugPrint('SocketService WebSocket Error: $error');
          _handleDisconnect();
        },
        onDone: () {
          debugPrint('SocketService WebSocket Closed');
          _handleDisconnect();
        },
      );
    } catch (e) {
      debugPrint('SocketService Connection Error: $e');
      _handleDisconnect();
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      sendMessage('ping');
    });
  }

  void _handleDisconnect() {
    disconnect(); // clean up current state
    
    if (_reconnectAttempts < _maxReconnectAttempts) {
      _reconnectAttempts++;
      final delaySeconds = _reconnectAttempts * 2; // Exponential-ish backoff: 2s, 4s, 6s...
      debugPrint('SocketService: Reconnecting in $delaySeconds seconds (Attempt $_reconnectAttempts/$_maxReconnectAttempts)');
      
      _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
        connect();
      });
    } else {
      debugPrint('SocketService: Max reconnect attempts reached. Giving up.');
    }
  }

  void sendMessage(String type, [Map<String, dynamic>? data]) {
    if (_channel != null) {
      final payload = {
        'type': type,
        if (data != null) 'data': data,
      };
      
      // Some simple messages like location update format lat/lnt at root of payload in WS Guide
      // Adjusting to make sure we support both formats easily
      if (data != null && data.containsKey('_merge_to_root')) {
        data.remove('_merge_to_root');
        payload.addAll(data);
        payload.remove('data');
      }

      final jsonStr = jsonEncode(payload);
      _channel!.sink.add(jsonStr);
      debugPrint('SocketService Sent: $jsonStr');
    } else {
      debugPrint('SocketService Warning: Cannot send message, socket not connected.');
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
    sendMessage('accept_job', {
      '_merge_to_root': true,
      'job_id': jobId,
    });
  }

  void rejectJob(String jobId) {
    sendMessage('reject_job', {
      '_merge_to_root': true,
      'job_id': jobId,
    });
  }
  
  void updateJobStatus(String jobId, String status) {
    sendMessage('job_status', {
      '_merge_to_root': true,
      'job_id': jobId,
      'status': status,
    });
  }

  void disconnect() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;

    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    _subscription?.cancel();
    _subscription = null;
    
    _channel?.sink.close();
    _channel = null;
  }
}
