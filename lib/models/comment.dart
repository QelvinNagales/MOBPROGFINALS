/// Comment model for project discussions
class ProjectComment {
  final String? id;
  final String projectId;
  final String userId;
  final String? parentCommentId;
  final String content;
  final bool isEdited;
  final int likesCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  // User info (populated from join)
  final String? userName;
  final String? userAvatar;
  
  // Replies (nested comments)
  final List<ProjectComment> replies;

  ProjectComment({
    this.id,
    required this.projectId,
    required this.userId,
    this.parentCommentId,
    required this.content,
    this.isEdited = false,
    this.likesCount = 0,
    this.createdAt,
    this.updatedAt,
    this.userName,
    this.userAvatar,
    List<ProjectComment>? replies,
  }) : replies = replies ?? [];

  factory ProjectComment.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    
    return ProjectComment(
      id: json['id'] as String?,
      projectId: json['project_id'] as String,
      userId: json['user_id'] as String,
      parentCommentId: json['parent_comment_id'] as String?,
      content: json['content'] as String,
      isEdited: json['is_edited'] as bool? ?? false,
      likesCount: json['likes_count'] as int? ?? 0,
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
      if (id != null) 'id': id,
      'project_id': projectId,
      'user_id': userId,
      'parent_comment_id': parentCommentId,
      'content': content,
      'is_edited': isEdited,
      'likes_count': likesCount,
    };
  }

  ProjectComment copyWith({
    String? id,
    String? projectId,
    String? userId,
    String? parentCommentId,
    String? content,
    bool? isEdited,
    int? likesCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userName,
    String? userAvatar,
    List<ProjectComment>? replies,
  }) {
    return ProjectComment(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      userId: userId ?? this.userId,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      content: content ?? this.content,
      isEdited: isEdited ?? this.isEdited,
      likesCount: likesCount ?? this.likesCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      replies: replies ?? this.replies,
    );
  }

  /// Format timestamp for display
  String get formattedTime {
    if (createdAt == null) return '';
    
    final now = DateTime.now();
    final diff = now.difference(createdAt!);
    
    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${createdAt!.day}/${createdAt!.month}/${createdAt!.year}';
    }
  }

  /// Check if this is a reply to another comment
  bool get isReply => parentCommentId != null;

  @override
  String toString() => 'Comment(id: $id, content: ${content.substring(0, content.length > 50 ? 50 : content.length)}...)';
}
