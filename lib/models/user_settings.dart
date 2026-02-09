/// User settings model for preferences and privacy
class UserSettings {
  final String? id;
  final String userId;
  
  // Privacy Settings
  final bool showEmail;
  final bool showOnlineStatus;
  final String allowMessagesFrom; // 'everyone', 'connections', 'nobody'
  final bool showProfileViews;
  
  // Notification Preferences
  final bool emailNotifications;
  final bool pushNotifications;
  final bool notifyConnectionRequests;
  final bool notifyMessages;
  final bool notifyProjectStars;
  final bool notifyComments;
  
  // Display Preferences
  final String theme; // 'light', 'dark', 'system'
  final String language;
  
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserSettings({
    this.id,
    required this.userId,
    this.showEmail = false,
    this.showOnlineStatus = true,
    this.allowMessagesFrom = 'connections',
    this.showProfileViews = true,
    this.emailNotifications = true,
    this.pushNotifications = true,
    this.notifyConnectionRequests = true,
    this.notifyMessages = true,
    this.notifyProjectStars = true,
    this.notifyComments = true,
    this.theme = 'system',
    this.language = 'en',
    this.createdAt,
    this.updatedAt,
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      showEmail: json['show_email'] as bool? ?? false,
      showOnlineStatus: json['show_online_status'] as bool? ?? true,
      allowMessagesFrom: json['allow_messages_from'] as String? ?? 'connections',
      showProfileViews: json['show_profile_views'] as bool? ?? true,
      emailNotifications: json['email_notifications'] as bool? ?? true,
      pushNotifications: json['push_notifications'] as bool? ?? true,
      notifyConnectionRequests: json['notify_connection_requests'] as bool? ?? true,
      notifyMessages: json['notify_messages'] as bool? ?? true,
      notifyProjectStars: json['notify_project_stars'] as bool? ?? true,
      notifyComments: json['notify_comments'] as bool? ?? true,
      theme: json['theme'] as String? ?? 'system',
      language: json['language'] as String? ?? 'en',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'show_email': showEmail,
      'show_online_status': showOnlineStatus,
      'allow_messages_from': allowMessagesFrom,
      'show_profile_views': showProfileViews,
      'email_notifications': emailNotifications,
      'push_notifications': pushNotifications,
      'notify_connection_requests': notifyConnectionRequests,
      'notify_messages': notifyMessages,
      'notify_project_stars': notifyProjectStars,
      'notify_comments': notifyComments,
      'theme': theme,
      'language': language,
    };
  }

  UserSettings copyWith({
    String? id,
    String? userId,
    bool? showEmail,
    bool? showOnlineStatus,
    String? allowMessagesFrom,
    bool? showProfileViews,
    bool? emailNotifications,
    bool? pushNotifications,
    bool? notifyConnectionRequests,
    bool? notifyMessages,
    bool? notifyProjectStars,
    bool? notifyComments,
    String? theme,
    String? language,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserSettings(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      showEmail: showEmail ?? this.showEmail,
      showOnlineStatus: showOnlineStatus ?? this.showOnlineStatus,
      allowMessagesFrom: allowMessagesFrom ?? this.allowMessagesFrom,
      showProfileViews: showProfileViews ?? this.showProfileViews,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      notifyConnectionRequests: notifyConnectionRequests ?? this.notifyConnectionRequests,
      notifyMessages: notifyMessages ?? this.notifyMessages,
      notifyProjectStars: notifyProjectStars ?? this.notifyProjectStars,
      notifyComments: notifyComments ?? this.notifyComments,
      theme: theme ?? this.theme,
      language: language ?? this.language,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get theme mode
  bool get isDarkMode => theme == 'dark';
  bool get isLightMode => theme == 'light';
  bool get isSystemTheme => theme == 'system';

  /// Check if user can receive messages from another user
  bool canReceiveMessageFrom(bool isConnection) {
    switch (allowMessagesFrom) {
      case 'everyone':
        return true;
      case 'connections':
        return isConnection;
      case 'nobody':
        return false;
      default:
        return isConnection;
    }
  }

  @override
  String toString() => 'UserSettings(userId: $userId, theme: $theme)';
}
