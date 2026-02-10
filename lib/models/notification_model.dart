/// Notification type enum
enum NotificationType {
  connectionRequest,
  connectionAccepted,
  projectStar,
  projectFork,
  mention,
  announcement,
  like,
  comment,
  collaboration,
  general,
}

/// Notification model class
/// Represents a notification in the app.
class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime timestamp;
  bool isRead;
  final String? actionUrl;
  final String? fromUser;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    DateTime? timestamp,
    this.isRead = false,
    this.actionUrl,
    this.fromUser,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Get appropriate icon for notification type
  String get notificationIcon {
    switch (type) {
      case NotificationType.connectionRequest:
        return '👋';
      case NotificationType.connectionAccepted:
        return '🎉';
      case NotificationType.projectStar:
        return '⭐';
      case NotificationType.projectFork:
        return '🍴';
      case NotificationType.mention:
        return '@';
      case NotificationType.announcement:
        return '📢';
      case NotificationType.like:
        return '❤️';
      case NotificationType.comment:
        return '💬';
      case NotificationType.collaboration:
        return '🤝';
      case NotificationType.general:
        return '🔔';
    }
  }

  /// Get time ago string
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 7) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  /// Mark notification as read
  void markAsRead() {
    isRead = true;
  }
}
