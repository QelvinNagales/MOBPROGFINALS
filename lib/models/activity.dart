/// Activity type enum
enum ActivityType {
  newConnection,
  projectCreated,
  projectUpdated,
  projectStarred,
  projectForked,
  profileUpdated,
  skillAdded,
  comment,
  collaborationStarted,
  achievementEarned,
}

/// Activity model class
/// Represents an event or action in the activity feed.
/// Enhanced for full-stack implementation with Supabase integration.
class Activity {
  final String? id;
  final String? userId;
  final ActivityType type;
  final String title;
  final String description;
  final String? targetUserId;
  final String? targetProjectId;
  final Map<String, dynamic>? metadata;
  final bool isPublic;
  final DateTime? timestamp;
  
  // User info (populated from join)
  final String? userName;
  final String? userAvatar;

  Activity({
    this.id,
    this.userId,
    required this.type,
    required this.title,
    required this.description,
    this.targetUserId,
    this.targetProjectId,
    this.metadata,
    this.isPublic = true,
    DateTime? timestamp,
    this.userName,
    this.userAvatar,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Create Activity from Supabase JSON response
  factory Activity.fromJson(Map<String, dynamic> json) {
    final profiles = json['profiles'] as Map<String, dynamic>?;
    
    return Activity(
      id: json['id'] as String?,
      userId: json['user_id'] as String?,
      type: _parseActivityType(json['type'] as String?),
      title: json['title'] as String? ?? 'Activity',
      description: json['description'] as String? ?? '',
      targetUserId: json['target_user_id'] as String?,
      targetProjectId: json['target_project_id'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      isPublic: json['is_public'] as bool? ?? true,
      timestamp: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : null,
      userName: profiles?['full_name'] as String?,
      userAvatar: profiles?['avatar_url'] as String?,
    );
  }

  /// Convert to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      'type': _activityTypeToString(type),
      'title': title,
      'description': description,
      'target_user_id': targetUserId,
      'target_project_id': targetProjectId,
      'metadata': metadata,
      'is_public': isPublic,
    };
  }

  /// Parse activity type from string
  static ActivityType _parseActivityType(String? typeStr) {
    switch (typeStr) {
      case 'project_created':
        return ActivityType.projectCreated;
      case 'project_updated':
        return ActivityType.projectUpdated;
      case 'project_starred':
        return ActivityType.projectStarred;
      case 'project_forked':
        return ActivityType.projectForked;
      case 'connection_made':
        return ActivityType.newConnection;
      case 'skill_added':
        return ActivityType.skillAdded;
      case 'profile_updated':
        return ActivityType.profileUpdated;
      case 'achievement_earned':
        return ActivityType.achievementEarned;
      case 'comment_added':
        return ActivityType.comment;
      case 'collaboration_started':
        return ActivityType.collaborationStarted;
      default:
        return ActivityType.profileUpdated;
    }
  }

  /// Convert activity type to string for database
  static String _activityTypeToString(ActivityType type) {
    switch (type) {
      case ActivityType.projectCreated:
        return 'project_created';
      case ActivityType.projectUpdated:
        return 'project_updated';
      case ActivityType.projectStarred:
        return 'project_starred';
      case ActivityType.projectForked:
        return 'project_forked';
      case ActivityType.newConnection:
        return 'connection_made';
      case ActivityType.skillAdded:
        return 'skill_added';
      case ActivityType.profileUpdated:
        return 'profile_updated';
      case ActivityType.achievementEarned:
        return 'achievement_earned';
      case ActivityType.comment:
        return 'comment_added';
      case ActivityType.collaborationStarted:
        return 'collaboration_started';
    }
  }

  /// Get appropriate icon for activity type
  String get activityIcon {
    switch (type) {
      case ActivityType.newConnection:
        return '🤝';
      case ActivityType.projectCreated:
        return '📁';
      case ActivityType.projectUpdated:
        return '📝';
      case ActivityType.projectStarred:
        return '⭐';
      case ActivityType.projectForked:
        return '🍴';
      case ActivityType.profileUpdated:
        return '✏️';
      case ActivityType.skillAdded:
        return '🎯';
      case ActivityType.comment:
        return '💬';
      case ActivityType.collaborationStarted:
        return '👥';
      case ActivityType.achievementEarned:
        return '🏆';
    }
  }

  /// Get time ago string
  String get timeAgo {
    if (timestamp == null) return '';
    
    final now = DateTime.now();
    final difference = now.difference(timestamp!);

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

  @override
  String toString() => 'Activity(id: $id, type: $type, title: $title)';
}

