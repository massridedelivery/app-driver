import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'socket_service.g.dart';

@riverpod
SocketService socketService(ref) {
  final service = SocketService();
  ref.onDispose(() => service.disconnect());
  return service;
}

class SocketService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  
  // Example dummy endpoint. Usually fetched from env or auth logic.
  final String _url = 'ws://echo.websocket.events'; 
  
  final StreamController<String> _messageController = StreamController<String>.broadcast();
  Stream<String> get messages => _messageController.stream;
  
  bool get isConnected => _channel != null;

  void connect() {
    if (_channel != null) return;
    
    try {
      _channel = WebSocketChannel.connect(Uri.parse(_url));
      
      _subscription = _channel!.stream.listen(
        (data) {
          _messageController.add(data.toString());
        },
        onError: (error) {
          print('WebSocket Error: $error');
          disconnect();
        },
        onDone: () {
          print('WebSocket Closed');
          disconnect();
        },
      );
    } catch (e) {
      print('WebSocket Connection Error: $e');
      disconnect();
    }
  }

  void sendMessage(String message) {
    if (_channel != null) {
      _channel!.sink.add(message);
    }
  }

  void disconnect() {
    _subscription?.cancel();
    _subscription = null;
    
    _channel?.sink.close();
    _channel = null;
  }
}

