import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../widgets/notification_tile.dart';
import '../services/theme_service.dart';

/// Notifications Screen
/// Displays all notifications in a modern minimalist list format.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Sample notifications data
  final List<AppNotification> _notifications = [
    AppNotification(
      id: '1',
      type: NotificationType.connectionRequest,
      title: 'New Connection Request',
      message: 'Sofia Rodriguez wants to connect with you',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      fromUser: 'Sofia Rodriguez',
    ),
    AppNotification(
      id: '2',
      type: NotificationType.projectStar,
      title: 'Project Starred',
      message: 'James Chen starred your "APC Campus Guide" project',
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      fromUser: 'James Chen',
    ),
    AppNotification(
      id: '3',
      type: NotificationType.connectionAccepted,
      title: 'Connection Accepted',
      message: 'Maria Santos accepted your connection request',
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      isRead: true,
      fromUser: 'Maria Santos',
    ),
    AppNotification(
      id: '4',
      type: NotificationType.projectFork,
      title: 'Project Forked',
      message: 'Nina Patel forked your "Student Budget Tracker" project',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
      fromUser: 'Nina Patel',
    ),
    AppNotification(
      id: '5',
      type: NotificationType.mention,
      title: 'You were mentioned',
      message:
          'Carlos Reyes mentioned you in a comment on "Study Group Finder"',
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
      isRead: true,
      fromUser: 'Carlos Reyes',
    ),
    AppNotification(
      id: '6',
      type: NotificationType.announcement,
      title: 'APC Network Update',
      message:
          'New features added! Check out the explore section to find study partners.',
      timestamp: DateTime.now().subtract(const Duration(days: 3)),
      isRead: true,
    ),
  ];

  int get _unreadCount =>
      _notifications.where((n) => !n.isRead).length;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        elevation: 0,
        title: Text(
          'Notifications',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppColors.darkText,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: isDark ? Colors.white : AppColors.darkText),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'Mark all read',
                style: TextStyle(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: isDark ? Colors.white70 : AppColors.darkText.withValues(alpha: 0.6)),
            color: isDark ? AppColors.darkCard : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) {
              if (value == 'clear') {
                _clearAllNotifications();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep_rounded, color: isDark ? Colors.white70 : AppColors.darkText.withValues(alpha: 0.6)),
                    const SizedBox(width: 10),
                    Text('Clear all', style: TextStyle(color: isDark ? Colors.white : AppColors.darkText)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.notifications_off_outlined,
                      size: 56,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No notifications',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "You're all caught up!",
                    style: TextStyle(
                      color: isDark ? Colors.white60 : AppColors.darkText.withValues(alpha: 0.6),
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Unread count banner
                if (_unreadCount > 0)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.primaryBlue.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.notifications_active_rounded,
                            size: 18,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '$_unreadCount unread notification${_unreadCount > 1 ? 's' : ''}',
                          style: TextStyle(
                            color: isDark ? AppColors.primaryBlue : const Color(0xFFD97706),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Notifications list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      return NotificationTile(
                        notification: notification,
                        onTap: () => _handleNotificationTap(notification),
                        onDismiss: () {
                          setState(() {
                            _notifications.removeAt(index);
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Notification dismissed'),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              action: SnackBarAction(
                                label: 'Undo',
                                onPressed: () {
                                  setState(() {
                                    _notifications.insert(index, notification);
                                  });
                                },
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  void _handleNotificationTap(AppNotification notification) {
    // Mark as read
    setState(() {
      notification.isRead = true;
    });

    // Handle different notification types
    switch (notification.type) {
      case NotificationType.connectionRequest:
        _showConnectionRequestDialog(notification);
        break;
      case NotificationType.projectStar:
      case NotificationType.projectFork:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Navigating to project...'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        break;
      default:
        _showNotificationDetails(notification);
    }
  }

  void _showConnectionRequestDialog(AppNotification notification) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Connection Request',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          content: Text(
            '${notification.fromUser} wants to connect with you.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Connection request declined'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
              child: Text(
                'Decline',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('You are now connected with ${notification.fromUser}!'),
                    backgroundColor: const Color(0xFF10B981),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
                setState(() {
                  _notifications.remove(notification);
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Accept'),
            ),
          ],
        );
      },
    );
  }

  void _showNotificationDetails(AppNotification notification) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.cardBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.lightBlue,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      notification.notificationIcon,
                      style: const TextStyle(fontSize: 26),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.timeAgo,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                notification.message,
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _markAllAsRead() {
    setState(() {
      for (var notification in _notifications) {
        notification.isRead = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('All notifications marked as read'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _clearAllNotifications() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Clear All Notifications',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          content: Text(
            'Are you sure you want to clear all notifications?',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _notifications.clear();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('All notifications cleared'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Clear All'),
            ),
          ],
        );
      },
    );
  }
}
