import 'package:flutter/material.dart';
import 'dart:async';

/// Order Timer Widget
/// Displays elapsed time since order creation with color coding
class OrderTimer extends StatefulWidget {
  final DateTime orderTime;
  final bool showFlashing;
  
  const OrderTimer({
    super.key,
    required this.orderTime,
    this.showFlashing = true,
  });

  @override
  State<OrderTimer> createState() => _OrderTimerState();
}

class _OrderTimerState extends State<OrderTimer> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    _updateElapsed();
    
    // Update every second
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateElapsed();
    });
  }

  void _updateElapsed() {
    final now = DateTime.now();
    final elapsed = now.difference(widget.orderTime);
    
    if (mounted) {
      setState(() {
        _elapsed = elapsed;
        
        // Flash if over 15 minutes
        if (widget.showFlashing && elapsed.inMinutes >= 15) {
          _isVisible = !_isVisible;
        } else {
          _isVisible = true;
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Color _getColor() {
    final minutes = _elapsed.inMinutes;
    
    if (minutes < 10) {
      return Colors.green;
    } else if (minutes < 15) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  String _formatDuration() {
    final minutes = _elapsed.inMinutes;
    final seconds = _elapsed.inSeconds % 60;
    
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      return '${hours}h ${remainingMinutes}m';
    }
    
    return '${minutes}m ${seconds}s';
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    
    return AnimatedOpacity(
      opacity: _isVisible ? 1.0 : 0.3,
      duration: const Duration(milliseconds: 500),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timer, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              _formatDuration(),
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
