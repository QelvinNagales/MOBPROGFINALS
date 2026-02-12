import 'package:flutter/material.dart';
import '../services/theme_service.dart';

/// Global key for showing toast notifications from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Service for showing toast notifications for chat messages
class ToastNotificationService {
  static final ToastNotificationService _instance = ToastNotificationService._internal();
  factory ToastNotificationService() => _instance;
  ToastNotificationService._internal();

  OverlayEntry? _currentOverlay;
  
  /// Show a chat message toast notification
  void showChatToast({
    required BuildContext context,
    required String senderName,
    required String message,
    String? senderAvatar,
    VoidCallback? onTap,
  }) {
    // Remove any existing toast
    hideToast();
    
    final overlay = Overlay.of(context);
    
    _currentOverlay = OverlayEntry(
      builder: (context) => _ChatToastWidget(
        senderName: senderName,
        message: message,
        senderAvatar: senderAvatar,
        onTap: () {
          hideToast();
          onTap?.call();
        },
        onDismiss: hideToast,
      ),
    );
    
    overlay.insert(_currentOverlay!);
    
    // Auto dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      hideToast();
    });
  }
  
  /// Hide the current toast
  void hideToast() {
    _currentOverlay?.remove();
    _currentOverlay = null;
  }
}

class _ChatToastWidget extends StatefulWidget {
  final String senderName;
  final String message;
  final String? senderAvatar;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const _ChatToastWidget({
    required this.senderName,
    required this.message,
    this.senderAvatar,
    this.onTap,
    this.onDismiss,
  });

  @override
  State<_ChatToastWidget> createState() => _ChatToastWidgetState();
}

class _ChatToastWidgetState extends State<_ChatToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPadding = MediaQuery.of(context).padding.top;
    
    return Positioned(
      top: topPadding + 10,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: GestureDetector(
            onTap: widget.onTap,
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity != null && details.primaryVelocity!.abs() > 100) {
                widget.onDismiss?.call();
              }
            },
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.darkCardBorder : AppColors.cardBorder,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: widget.senderAvatar != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                widget.senderAvatar!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.person_rounded,
                                  color: AppColors.primaryBlue,
                                  size: 24,
                                ),
                              ),
                            )
                          : Icon(
                              Icons.chat_bubble_rounded,
                              color: AppColors.primaryBlue,
                              size: 24,
                            ),
                    ),
                    const SizedBox(width: 12),
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Text(
                                'New Message',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'now',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark 
                                      ? AppColors.darkTextSecondary 
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.senderName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isDark 
                                  ? AppColors.darkTextPrimary 
                                  : AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.message,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark 
                                  ? AppColors.darkTextSecondary 
                                  : AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Arrow icon
                    Icon(
                      Icons.chevron_right_rounded,
                      color: isDark 
                          ? AppColors.darkTextSecondary 
                          : AppColors.textSecondary,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Global instance
final toastService = ToastNotificationService();
