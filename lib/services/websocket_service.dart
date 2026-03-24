import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:logger/logger.dart';
import '../models/threat_event.dart';

/// Real-time WebSocket connection for live threat intelligence updates.
class WebSocketService {
  final String wsUrl;
  final Logger _log = Logger();

  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int maxReconnectAttempts = 10;

  final _eventController = StreamController<ThreatEvent>.broadcast();
  Stream<ThreatEvent> get eventStream => _eventController.stream;

  final _statusController = StreamController<ConnectionStatus>.broadcast();
  Stream<ConnectionStatus> get statusStream => _statusController.stream;

  WebSocketService({required this.wsUrl});

  /// Connect to the intelligence WebSocket feed.
  void connect() {
    try {
      _statusController.add(ConnectionStatus.connecting);
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _channel!.stream.listen(
        (data) {
          _reconnectAttempts = 0;
          _statusController.add(ConnectionStatus.connected);
          _handleMessage(data as String);
        },
        onError: (error) {
          _log.e('WebSocket error: $error');
          _statusController.add(ConnectionStatus.error);
          _scheduleReconnect();
        },
        onDone: () {
          _log.w('WebSocket closed');
          _statusController.add(ConnectionStatus.disconnected);
          _scheduleReconnect();
        },
      );

      _statusController.add(ConnectionStatus.connected);
      _log.i('WebSocket connected to $wsUrl');
    } catch (e) {
      _log.e('WebSocket connection failed: $e');
      _statusController.add(ConnectionStatus.error);
      _scheduleReconnect();
    }
  }

  void _handleMessage(String rawData) {
    try {
      final json = jsonDecode(rawData) as Map<String, dynamic>;
      final event = ThreatEvent.fromJson(json);
      _eventController.add(event);
    } catch (e) {
      _log.w('Failed to parse WebSocket message: $e');
    }
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= maxReconnectAttempts) {
      _log.e('Max reconnection attempts reached');
      _statusController.add(ConnectionStatus.failed);
      return;
    }

    _reconnectAttempts++;
    final delay = Duration(seconds: _reconnectAttempts * 2);
    _log.i('Reconnecting in ${delay.inSeconds}s (attempt $_reconnectAttempts)');

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, connect);
  }

  /// Send a message through the WebSocket.
  void send(Map<String, dynamic> data) {
    _channel?.sink.add(jsonEncode(data));
  }

  void dispose() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _eventController.close();
    _statusController.close();
  }
}

enum ConnectionStatus {
  connecting,
  connected,
  disconnected,
  error,
  failed,
}
