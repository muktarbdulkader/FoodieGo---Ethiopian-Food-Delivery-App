import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_theme.dart';

/// Widget to share the app with others
class ShareAppWidget extends StatelessWidget {
  final String? userReferralCode;

  const ShareAppWidget({
    super.key,
    this.userReferralCode,
  });

  void _shareApp(BuildContext context, String platform) {
    final message = _getShareMessage();

    // Use native share
    Share.share(message, subject: 'Join me on FoodieGo!');
  }

  String _getShareMessage() {
    if (userReferralCode != null && userReferralCode!.isNotEmpty) {
      return '🍽️ Order delicious Ethiopian food with FoodieGo!\n\n'
          '🎉 Use my code "$userReferralCode" to get 50 ETB off your first order!\n\n'
          '📱 Download now and enjoy the best local cuisine delivered to your door!';
    }
    return '🍽️ Discover the best Ethiopian food delivery app!\n\n'
        '🚀 FoodieGo delivers delicious local cuisine to your doorstep.\n\n'
        '📱 Download now and enjoy exclusive deals!';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Share FoodieGo',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tell your friends about us!',
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildShareButton(
                context,
                'WhatsApp',
                Icons.chat,
                const Color(0xFF25D366),
              ),
              _buildShareButton(
                context,
                'Telegram',
                Icons.send,
                const Color(0xFF0088cc),
              ),
              _buildShareButton(
                context,
                'Copy',
                Icons.copy,
                Colors.grey.shade700,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShareButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
  ) {
    return GestureDetector(
      onTap: () => _shareApp(context, label),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

/// App rating request widget
class RateAppWidget extends StatelessWidget {
  final VoidCallback? onRate;
  final VoidCallback? onLater;

  const RateAppWidget({
    super.key,
    this.onRate,
    this.onLater,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.1),
            AppTheme.primaryColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.star,
            color: Color(0xFFFFD700),
            size: 40,
          ),
          const SizedBox(height: 12),
          const Text(
            'Enjoying FoodieGo?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Rate us on the app store!',
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onLater,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade600,
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Later'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onRate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Rate 5 Stars'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
