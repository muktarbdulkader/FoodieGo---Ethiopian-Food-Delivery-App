import 'package:flutter/foundation.dart';
import '../../core/services/websocket_service.dart';

/// WebSocket Provider
/// Manages WebSocket connection state and provides access to WebSocket service
class WebSocketProvider with ChangeNotifier {
  final WebSocketService _webSocketService = WebSocketService();
  
  ConnectionState _connectionState = ConnectionState.disconnected;
  
  WebSocketProvider() {
    // Listen to connection state changes
    _webSocketService.connectionStateStream.listen((state) {
      _connectionState = state;
      notifyListeners();
    });
  }
  
  /// Get current connection state
  ConnectionState get connectionState => _connectionState;
  
  /// Check if connected
  bool get isConnected => _connectionState == ConnectionState.connected;
  
  /// Get connection state as string
  String get connectionStateString {
    switch (_connectionState) {
      case ConnectionState.connected:
        return 'Connected';
      case ConnectionState.connecting:
        return 'Connecting...';
      case ConnectionState.reconnecting:
        return 'Reconnecting...';
      case ConnectionState.disconnected:
        return 'Disconnected';
    }
  }
  
  /// Connect to WebSocket server
  Future<void> connect(String token) async {
    await _webSocketService.connect(token);
  }
  
  /// Disconnect from WebSocket server
  void disconnect() {
    _webSocketService.disconnect();
  }
  
  /// Join a room
  void joinRoom(String roomName) {
    _webSocketService.joinRoom(roomName);
  }
  
  /// Leave a room
  void leaveRoom(String roomName) {
    _webSocketService.leaveRoom(roomName);
  }
  
  /// Listen to an event
  void on(String eventName, Function(dynamic) callback) {
    _webSocketService.on(eventName, callback);
  }
  
  /// Remove event listener
  void off(String eventName, [Function(dynamic)? callback]) {
    _webSocketService.off(eventName, callback);
  }
  
  /// Emit an event
  void emit(String eventName, dynamic data) {
    _webSocketService.emit(eventName, data);
  }
  
  @override
  void dispose() {
    _webSocketService.dispose();
    super.dispose();
  }
}
