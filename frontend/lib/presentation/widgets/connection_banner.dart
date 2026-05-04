import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/websocket/websocket_provider.dart';
import '../../core/services/websocket_service.dart' as ws;

/// Connection Banner Widget
/// Shows a banner when connection is lost or restored
class ConnectionBanner extends StatefulWidget {
  final Widget child;
  
  const ConnectionBanner({
    super.key,
    required this.child,
  });

  @override
  State<ConnectionBanner> createState() => _ConnectionBannerState();
}

class _ConnectionBannerState extends State<ConnectionBanner> {
  bool _showRestoredMessage = false;
  
  @override
  Widget build(BuildContext context) {
    return Consumer<WebSocketProvider>(
      builder: (context, webSocketProvider, child) {
        final state = webSocketProvider.connectionState;
        
        // Show "Connection restored" message briefly
        if (state == ws.ConnectionState.connected && _showRestoredMessage) {
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              setState(() {
                _showRestoredMessage = false;
              });
            }
          });
        }
        
        // Track when connection is restored
        if (state == ws.ConnectionState.connected && !_showRestoredMessage) {
          // Check if we were previously disconnected
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _showRestoredMessage = true;
              });
            }
          });
        }
        
        return Stack(
          children: [
            widget.child,
            
            // Connection lost banner
            if (state == ws.ConnectionState.disconnected ||
                state == ws.ConnectionState.reconnecting)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Material(
                  elevation: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    color: state == ws.ConnectionState.reconnecting
                        ? Colors.orange
                        : Colors.red,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            state == ws.ConnectionState.reconnecting
                                ? 'Connection lost. Attempting to reconnect...'
                                : 'No connection. Please check your internet.',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            
            // Connection restored banner
            if (_showRestoredMessage && state == ws.ConnectionState.connected)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Material(
                  elevation: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    color: Colors.green,
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white, size: 20),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Connection restored',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
