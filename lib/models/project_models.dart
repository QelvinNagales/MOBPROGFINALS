/// Model for project comments
class ProjectComment {
  final String? id;
  final String projectId;
  final String userId;
  final String content;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  // User info (populated from join)
  final String? userName;
  final String? userAvatar;

  ProjectComment({
    this.id,
    required this.projectId,
    required this.userId,
    required this.content,
    this.createdAt,
    this.updatedAt,
    this.userName,
    this.userAvatar,
  });

  factory ProjectComment.fromJson(Map<String, dynamic> json) {
    // Support both 'profiles' (from Supabase join) and 'user' keys
    final user = (json['profiles'] ?? json['user']) as Map<String, dynamic>?;
    
    return ProjectComment(
      id: json['id'] as String?,
      projectId: json['project_id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      userName: user?['full_name'] as String?,
      userAvatar: user?['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'project_id': projectId,
      'user_id': userId,
      'content': content,
    };
  }

  String get timeAgo {
    if (createdAt == null) return '';
    final diff = DateTime.now().difference(createdAt!);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${createdAt!.day}/${createdAt!.month}/${createdAt!.year}';
  }
}

/// Model for collaboration requests
class CollaborationRequest {
  final String? id;
  final String projectId;
  final String userId;
  final String? message;
  final String status; // 'pending', 'accepted', 'rejected'
  final DateTime? createdAt;
  
  // User info
  final String? userName;
  final String? userAvatar;
  final String? userHeadline;

  CollaborationRequest({
    this.id,
    required this.projectId,
    required this.userId,
    this.message,
    this.status = 'pending',
    this.createdAt,
    this.userName,
    this.userAvatar,
    this.userHeadline,
  });

  factory CollaborationRequest.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    
    return CollaborationRequest(
      id: json['id'] as String?,
      projectId: json['project_id'] as String,
      userId: json['user_id'] as String,
      message: json['message'] as String?,
      status: json['status'] as String? ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      userName: user?['full_name'] as String?,
      userAvatar: user?['avatar_url'] as String?,
      userHeadline: user?['bio'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'project_id': projectId,
      'user_id': userId,
      'message': message,
      'status': status,
    };
  }
}
