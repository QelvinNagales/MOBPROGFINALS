import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/connectivity_service.dart';
import '../services/theme_service.dart';

/// Widget that shows an offline banner when there's no network connection
class OfflineIndicator extends StatelessWidget {
  final Widget child;
  
  const OfflineIndicator({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: ConnectivityService(),
      child: Consumer<ConnectivityService>(
        builder: (context, connectivity, _) {
          return Column(
            children: [
              // Offline banner
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: connectivity.isConnected ? 0 : null,
                child: connectivity.isConnected
                    ? const SizedBox.shrink()
                    : _OfflineBanner(),
              ),
              // Main content
              Expanded(child: child),
            ],
          );
        },
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 8,
        left: 16,
        right: 16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red.shade700,
            Colors.red.shade600,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            const Text(
              'No internet connection',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A simpler inline offline indicator for specific screens
class OfflineBadge extends StatelessWidget {
  const OfflineBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityService>(
      builder: (context, connectivity, _) {
        if (connectivity.isConnected) {
          return const SizedBox.shrink();
        }
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_rounded, size: 16, color: Colors.red.shade700),
              const SizedBox(width: 8),
              Text(
                'Offline - Some features may be unavailable',
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
