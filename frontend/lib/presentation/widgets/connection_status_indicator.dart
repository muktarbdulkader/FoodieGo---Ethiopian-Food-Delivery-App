import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/websocket/websocket_provider.dart';
import '../../core/services/websocket_service.dart' as ws;

/// Connection Status Indicator Widget
/// Displays the current WebSocket connection state
class ConnectionStatusIndicator extends StatelessWidget {
  final bool showLabel;
  
  const ConnectionStatusIndicator({
    super.key,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<WebSocketProvider>(
      builder: (context, webSocketProvider, child) {
        final state = webSocketProvider.connectionState;
        
        Color color;
        IconData icon;
        String label;
        
        switch (state) {
          case ws.ConnectionState.connected:
            color = Colors.green;
            icon = Icons.wifi;
            label = 'Live';
            break;
          case ws.ConnectionState.connecting:
            color = Colors.orange;
            icon = Icons.wifi_tethering;
            label = 'Connecting';
            break;
          case ws.ConnectionState.reconnecting:
            color = Colors.orange;
            icon = Icons.wifi_tethering;
            label = 'Reconnecting';
            break;
          case ws.ConnectionState.disconnected:
            color = Colors.red;
            icon = Icons.wifi_off;
            label = 'Offline';
            break;
        }
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 16),
              if (showLabel) ...[
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              if (state == ws.ConnectionState.connecting || 
                  state == ws.ConnectionState.reconnecting) ...[
                const SizedBox(width: 4),
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
