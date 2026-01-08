import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Widget to display errors with retry functionality
class ErrorRecoveryWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final bool isNetworkError;
  final bool isCompact;

  const ErrorRecoveryWidget({
    super.key,
    required this.message,
    required this.onRetry,
    this.isNetworkError = false,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompact) return _buildCompact();
    return _buildFull();
  }

  Widget _buildFull() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: (isNetworkError
                        ? AppTheme.accentYellow
                        : AppTheme.errorColor)
                    .withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isNetworkError
                    ? Icons.wifi_off_rounded
                    : Icons.error_outline_rounded,
                size: 64,
                color: isNetworkError
                    ? AppTheme.accentYellow
                    : AppTheme.errorColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isNetworkError ? 'Connection Lost' : 'Something Went Wrong',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _buildRetryButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildCompact() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (isNetworkError ? AppTheme.accentYellow : AppTheme.errorColor)
            .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isNetworkError ? AppTheme.accentYellow : AppTheme.errorColor)
              .withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isNetworkError
                ? Icons.wifi_off_rounded
                : Icons.error_outline_rounded,
            color: isNetworkError ? AppTheme.accentYellow : AppTheme.errorColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRetryButton() {
    return GestureDetector(
      onTap: onRetry,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.buttonShadow,
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.refresh_rounded, color: Colors.white),
            SizedBox(width: 10),
            Text(
              'Try Again',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Network status banner that shows when offline
class NetworkStatusBanner extends StatelessWidget {
  final bool isOnline;
  final VoidCallback? onRetry;

  const NetworkStatusBanner({
    super.key,
    required this.isOnline,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: isOnline ? 0 : 50,
      child: isOnline
          ? const SizedBox.shrink()
          : Container(
              color: AppTheme.errorColor,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.wifi_off, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'No internet connection',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                  if (onRetry != null)
                    GestureDetector(
                      onTap: onRetry,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          'Retry',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

/// Loading overlay with cancel option for long operations
class LoadingOverlay extends StatelessWidget {
  final String message;
  final VoidCallback? onCancel;
  final bool showCancel;

  const LoadingOverlay({
    super.key,
    this.message = 'Loading...',
    this.onCancel,
    this.showCancel = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppTheme.primaryColor),
              const SizedBox(height: 20),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              if (showCancel && onCancel != null) ...[
                const SizedBox(height: 20),
                TextButton(
                  onPressed: onCancel,
                  child: const Text('Cancel'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
