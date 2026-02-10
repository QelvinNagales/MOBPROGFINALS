import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/theme_service.dart';

/// NotificationTile Widget
/// Displays a notification item in a modern minimalist style.
class NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const NotificationTile({
    super.key,
    required this.notification,
    this.onTap,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss?.call(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.delete_rounded,
          color: Colors.white,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: notification.isRead 
              ? (isDark ? AppColors.darkCard : Colors.white)
              : AppColors.primaryBlue.withValues(alpha: isDark ? 0.15 : 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notification.isRead
                ? (isDark ? Colors.white12 : AppColors.cardBorder)
                : AppColors.primaryBlue.withValues(alpha: 0.3),
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Notification icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getNotificationColor().withValues(alpha: isDark ? 0.2 : 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    notification.notificationIcon,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(width: 14),
                // Notification content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: notification.isRead
                                    ? FontWeight.w500
                                    : FontWeight.w700,
                                color: isDark ? Colors.white : AppColors.darkText,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: AppColors.primaryBlue,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        notification.message,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white60 : AppColors.darkText.withValues(alpha: 0.6),
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        notification.timeAgo,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white38 : AppColors.darkText.withValues(alpha: 0.4),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getNotificationColor() {
    switch (notification.type) {
      case NotificationType.connectionRequest:
        return const Color(0xFF3B82F6);
      case NotificationType.connectionAccepted:
        return const Color(0xFF10B981);
      case NotificationType.projectStar:
        return AppColors.primaryBlue;
      case NotificationType.projectFork:
        return const Color(0xFF8B5CF6);
      case NotificationType.mention:
        return const Color(0xFF6366F1);
      case NotificationType.announcement:
        return const Color(0xFFEF4444);
      case NotificationType.like:
        return const Color(0xFFEC4899);
      case NotificationType.comment:
        return const Color(0xFF06B6D4);
      case NotificationType.collaboration:
        return const Color(0xFF10B981);
      case NotificationType.general:
        return const Color(0xFF6B7280);
    }
  }
}
