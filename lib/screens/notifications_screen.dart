import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../widgets/notification_tile.dart';
import '../services/theme_service.dart';
import '../services/supabase_service.dart';

/// Notifications Screen
/// Displays all notifications fetched from Supabase.
class NotificationsScreen extends StatefulWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;
  
  const NotificationsScreen({super.key, this.scaffoldKey});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    
    try {
      final data = await SupabaseService.getMyNotifications();
      
      if (mounted) {
        setState(() {
          _notifications = data.map((n) => AppNotification(
            id: n['id'] as String,
            type: _parseNotificationType(n['type'] as String?),
            title: n['title'] as String? ?? 'Notification',
            message: n['message'] as String? ?? '',
            timestamp: DateTime.tryParse(n['created_at'] as String? ?? '') ?? DateTime.now(),
            isRead: n['is_read'] as bool? ?? false,
            fromUser: n['from_user'] as String?,
          )).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      debugPrint('Error loading notifications: $e');
    }
  }

  NotificationType _parseNotificationType(String? type) {
    switch (type) {
      case 'connection_request':
        return NotificationType.connectionRequest;
      case 'connection_accepted':
        return NotificationType.connectionAccepted;
      case 'project_star':
        return NotificationType.projectStar;
      case 'project_fork':
        return NotificationType.projectFork;
      case 'mention':
        return NotificationType.mention;
      case 'announcement':
        return NotificationType.announcement;
      case 'like':
        return NotificationType.like;
      case 'comment':
        return NotificationType.comment;
      case 'collaboration_started':
        return NotificationType.collaboration;
      default:
        return NotificationType.general;
    }
  }

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.menu_rounded,
            color: isDark ? Colors.white : AppColors.darkText,
          ),
          onPressed: () => widget.scaffoldKey?.currentState?.openDrawer(),
        ),
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
              } else if (value == 'refresh') {
                _loadNotifications();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh_rounded, color: isDark ? Colors.white70 : AppColors.darkText.withValues(alpha: 0.6)),
                    const SizedBox(width: 10),
                    Text('Refresh', style: TextStyle(color: isDark ? Colors.white : AppColors.darkText)),
                  ],
                ),
              ),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
          : RefreshIndicator(
              onRefresh: _loadNotifications,
              color: AppColors.primaryBlue,
              child: _notifications.isEmpty
                  ? _buildEmptyState(isDark)
                  : _buildNotificationsList(isDark),
            ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
        Center(
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
        ),
      ],
    );
  }

  Widget _buildNotificationsList(bool isDark) {
    return Column(
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
                onDismiss: () => _dismissNotification(notification, index),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _dismissNotification(AppNotification notification, int index) async {
    final removed = _notifications[index];
    setState(() {
      _notifications.removeAt(index);
    });
    
    // Delete from database
    try {
      await SupabaseService.client
          .from('notifications')
          .delete()
          .eq('id', notification.id);
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Notification dismissed'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              // Re-insert
              try {
                await SupabaseService.client.from('notifications').insert({
                  'id': removed.id,
                  'user_id': SupabaseService.userId,
                  'type': removed.type.name,
                  'title': removed.title,
                  'message': removed.message,
                  'is_read': removed.isRead,
                  'created_at': removed.timestamp.toIso8601String(),
                });
                _loadNotifications();
              } catch (e) {
                debugPrint('Error restoring notification: $e');
              }
            },
          ),
        ),
      );
    }
  }

  void _handleNotificationTap(AppNotification notification) async {
    // Mark as read in database
    if (!notification.isRead) {
      await SupabaseService.markNotificationRead(notification.id);
      setState(() {
        notification.isRead = true;
      });
    }

    // Handle different notification types
    switch (notification.type) {
      case NotificationType.connectionRequest:
        _showNotificationDetails(notification);
        break;
      case NotificationType.connectionAccepted:
        _showNotificationDetails(notification);
        break;
      case NotificationType.projectStar:
      case NotificationType.projectFork:
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Navigating to project...'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
        break;
      default:
        _showNotificationDetails(notification);
    }
  }

  void _showNotificationDetails(AppNotification notification) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
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
                    color: isDark ? Colors.white24 : AppColors.cardBorder,
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
                      color: AppColors.primaryBlue.withValues(alpha: 0.2),
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
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppColors.darkText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.timeAgo,
                          style: TextStyle(
                            color: isDark ? Colors.white54 : AppColors.darkText.withValues(alpha: 0.5),
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
                  color: isDark ? Colors.white70 : AppColors.darkText.withValues(alpha: 0.7),
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

  Future<void> _markAllAsRead() async {
    await SupabaseService.markAllNotificationsRead();
    setState(() {
      for (var notification in _notifications) {
        notification.isRead = true;
      }
    });
    if (mounted) {
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
  }

  void _clearAllNotifications() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkCard : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Clear All Notifications',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.darkText,
            ),
          ),
          content: Text(
            'Are you sure you want to clear all notifications?',
            style: TextStyle(color: isDark ? Colors.white60 : AppColors.darkText.withValues(alpha: 0.6)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: isDark ? Colors.white60 : AppColors.darkText.withValues(alpha: 0.6)),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                
                // Delete all from database
                if (SupabaseService.userId != null) {
                  try {
                    await SupabaseService.client
                        .from('notifications')
                        .delete()
                        .eq('user_id', SupabaseService.userId!);
                  } catch (e) {
                    debugPrint('Error clearing notifications: $e');
                  }
                }
                
                setState(() {
                  _notifications.clear();
                });
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('All notifications cleared'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }
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
