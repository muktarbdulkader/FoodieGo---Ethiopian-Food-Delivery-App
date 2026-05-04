import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../constants/api_constants.dart';

/// WebSocket Service for real-time communication
/// Singleton pattern for global access
class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  IO.Socket? _socket;
  String? _token;
  
  // Connection state
  ConnectionState _connectionState = ConnectionState.disconnected;
  final _connectionStateController = StreamController<ConnectionState>.broadcast();
  
  // Event listeners
  final Map<String, List<Function(dynamic)>> _eventListeners = {};
  
  // Offline queue for messages
  final List<Map<String, dynamic>> _offlineQueue = [];
  
  // Reconnection settings
  int _reconnectAttempts = 0;
  final int _maxReconnectAttempts = 10;
  Timer? _reconnectTimer;
  
  // Heartbeat
  Timer? _heartbeatTimer;
  
  /// Get connection state stream
  Stream<ConnectionState> get connectionStateStream => _connectionStateController.stream;
  
  /// Get current connection state
  ConnectionState get connectionState => _connectionState;
  
  /// Check if connected
  bool get isConnected => _connectionState == ConnectionState.connected;
  
  /// Initialize WebSocket connection
  Future<void> connect(String token) async {
    if (_socket != null && _socket!.connected) {
      debugPrint('[WEBSOCKET] Already connected');
      return;
    }
    
    _token = token;
    _updateConnectionState(ConnectionState.connecting);
    
    try {
      // Get backend URL from API constants
      final backendUrl = ApiConstants.baseUrl.replaceAll('/api', '');
      
      debugPrint('[WEBSOCKET] Connecting to $backendUrl');
      
      _socket = IO.io(
        backendUrl,
        IO.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionAttempts(_maxReconnectAttempts)
            .setReconnectionDelay(1000)
            .setReconnectionDelayMax(30000)
            .setAuth({'token': token})
            .build(),
      );
      
      _setupEventHandlers();
      
    } catch (e) {
      debugPrint('[WEBSOCKET] Connection error: $e');
      _updateConnectionState(ConnectionState.disconnected);
      _scheduleReconnect();
    }
  }
  
  /// Setup socket event handlers
  void _setupEventHandlers() {
    if (_socket == null) return;
    
    _socket!.onConnect((_) {
      debugPrint('[WEBSOCKET] Connected');
      _updateConnectionState(ConnectionState.connected);
      _reconnectAttempts = 0;
      _startHeartbeat();
      _processOfflineQueue();
    });
    
    _socket!.onDisconnect((_) {
      debugPrint('[WEBSOCKET] Disconnected');
      _updateConnectionState(ConnectionState.disconnected);
      _stopHeartbeat();
      _scheduleReconnect();
    });
    
    _socket!.onConnectError((error) {
      debugPrint('[WEBSOCKET] Connection error: $error');
      _updateConnectionState(ConnectionState.disconnected);
    });
    
    _socket!.onError((error) {
      debugPrint('[WEBSOCKET] Error: $error');
    });
    
    _socket!.on('connection:established', (data) {
      debugPrint('[WEBSOCKET] Connection established: $data');
    });
    
    _socket!.on('error', (data) {
      debugPrint('[WEBSOCKET] Server error: $data');
    });
    
    _socket!.on('pong', (data) {
      debugPrint('[WEBSOCKET] Pong received');
    });
    
    // Setup custom event listeners
    _eventListeners.forEach((eventName, callbacks) {
      _socket!.on(eventName, (data) {
        for (var callback in callbacks) {
          callback(data);
        }
      });
    });
  }
  
  /// Start heartbeat to keep connection alive
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_socket != null && _socket!.connected) {
        _socket!.emit('ping');
      }
    });
  }
  
  /// Stop heartbeat
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }
  
  /// Schedule reconnection with exponential backoff
  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('[WEBSOCKET] Max reconnection attempts reached');
      _updateConnectionState(ConnectionState.disconnected);
      return;
    }
    
    _reconnectAttempts++;
    final delay = Duration(
      milliseconds: (1000 * (1 << (_reconnectAttempts - 1))).clamp(1000, 30000),
    );
    
    debugPrint('[WEBSOCKET] Reconnecting in ${delay.inSeconds}s (attempt $_reconnectAttempts)');
    _updateConnectionState(ConnectionState.reconnecting);
    
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      if (_token != null) {
        connect(_token!);
      }
    });
  }
  
  /// Update connection state and notify listeners
  void _updateConnectionState(ConnectionState state) {
    _connectionState = state;
    _connectionStateController.add(state);
  }
  
  /// Join a room
  void joinRoom(String roomName) {
    if (_socket == null || !_socket!.connected) {
      debugPrint('[WEBSOCKET] Cannot join room - not connected');
      return;
    }
    
    debugPrint('[WEBSOCKET] Joining room: $roomName');
    _socket!.emit('join:room', {'roomName': roomName});
    
    // Listen for room joined confirmation
    _socket!.once('room:joined', (data) {
      debugPrint('[WEBSOCKET] Joined room: ${data['roomName']}');
    });
  }
  
  /// Leave a room
  void leaveRoom(String roomName) {
    if (_socket == null || !_socket!.connected) {
      return;
    }
    
    debugPrint('[WEBSOCKET] Leaving room: $roomName');
    _socket!.emit('leave:room', {'roomName': roomName});
  }
  
  /// Listen to an event
  void on(String eventName, Function(dynamic) callback) {
    if (!_eventListeners.containsKey(eventName)) {
      _eventListeners[eventName] = [];
    }
    
    _eventListeners[eventName]!.add(callback);
    
    // If already connected, register the listener immediately
    if (_socket != null && _socket!.connected) {
      _socket!.on(eventName, callback);
    }
  }
  
  /// Remove event listener
  void off(String eventName, [Function(dynamic)? callback]) {
    if (callback != null) {
      _eventListeners[eventName]?.remove(callback);
    } else {
      _eventListeners.remove(eventName);
    }
    
    if (_socket != null) {
      _socket!.off(eventName);
    }
  }
  
  /// Emit an event
  void emit(String eventName, dynamic data) {
    if (_socket == null || !_socket!.connected) {
      debugPrint('[WEBSOCKET] Cannot emit - not connected. Queuing message.');
      _offlineQueue.add({'event': eventName, 'data': data});
      return;
    }
    
    _socket!.emit(eventName, data);
  }
  
  /// Process offline queue
  void _processOfflineQueue() {
    if (_offlineQueue.isEmpty) return;
    
    debugPrint('[WEBSOCKET] Processing ${_offlineQueue.length} queued messages');
    
    for (var message in _offlineQueue) {
      _socket!.emit(message['event'], message['data']);
    }
    
    _offlineQueue.clear();
  }
  
  /// Disconnect
  void disconnect() {
    debugPrint('[WEBSOCKET] Disconnecting');
    
    _stopHeartbeat();
    _reconnectTimer?.cancel();
    
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }
    
    _updateConnectionState(ConnectionState.disconnected);
  }
  
  /// Dispose
  void dispose() {
    disconnect();
    _connectionStateController.close();
    _eventListeners.clear();
    _offlineQueue.clear();
  }
}

/// Connection state enum
enum ConnectionState {
  connected,
  connecting,
  reconnecting,
  disconnected,
}
