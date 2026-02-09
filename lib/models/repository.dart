/// Repository/Project model class
/// Represents a project in the student's portfolio.
/// Enhanced for full-stack implementation with additional fields.
class Repository {
  final String? id;
  final String? userId;
  String name;
  String description;
  String longDescription;
  String language;
  int starsCount;
  int forksCount;
  int viewsCount;
  int commentsCount;
  bool isPublic;
  String status; // 'idea', 'in_progress', 'completed', 'archived'
  List<String> topics;
  List<String> technologies;
  String? githubUrl;
  String? demoUrl;
  String? thumbnailUrl;
  DateTime? startDate;
  DateTime? endDate;
  DateTime? createdAt;
  DateTime? updatedAt;
  
  // Owner info (populated from join)
  String? ownerName;
  String? ownerAvatar;

  // Backward-compatible getters
  int get stars => starsCount;
  int get forks => forksCount;
  DateTime? get lastUpdated => updatedAt;

  Repository({
    this.id,
    this.userId,
    required this.name,
    required this.description,
    this.longDescription = '',
    this.language = 'Dart',
    this.starsCount = 0,
    this.forksCount = 0,
    this.viewsCount = 0,
    this.commentsCount = 0,
    this.isPublic = true,
    this.status = 'in_progress',
    List<String>? topics,
    List<String>? technologies,
    this.githubUrl,
    this.demoUrl,
    this.thumbnailUrl,
    this.startDate,
    this.endDate,
    this.createdAt,
    this.updatedAt,
    this.ownerName,
    this.ownerAvatar,
  })  : topics = topics ?? [],
        technologies = technologies ?? [];

  /// Create Repository from Supabase JSON response
  factory Repository.fromJson(Map<String, dynamic> json) {
    final owner = json['owner'] as Map<String, dynamic>?;
    
    return Repository(
      id: json['id'] as String?,
      userId: json['user_id'] as String?,
      name: json['name'] as String? ?? 'Untitled Project',
      description: json['description'] as String? ?? '',
      longDescription: json['long_description'] as String? ?? '',
      language: json['language'] as String? ?? 'Dart',
      starsCount: json['stars_count'] as int? ?? json['stars'] as int? ?? 0,
      forksCount: json['forks_count'] as int? ?? json['forks'] as int? ?? 0,
      viewsCount: json['views_count'] as int? ?? 0,
      commentsCount: json['comments_count'] as int? ?? 0,
      isPublic: json['is_public'] as bool? ?? true,
      status: json['status'] as String? ?? 'in_progress',
      topics: (json['topics'] as List<dynamic>?)?.cast<String>() ?? [],
      technologies: (json['technologies'] as List<dynamic>?)?.cast<String>() ?? [],
      githubUrl: json['github_url'] as String?,
      demoUrl: json['demo_url'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      startDate: json['start_date'] != null 
          ? DateTime.parse(json['start_date'] as String)
          : null,
      endDate: json['end_date'] != null 
          ? DateTime.parse(json['end_date'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      ownerName: owner?['full_name'] as String?,
      ownerAvatar: owner?['avatar_url'] as String?,
    );
  }

  /// Convert to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      'name': name,
      'description': description,
      'long_description': longDescription,
      'language': language,
      'stars_count': starsCount,
      'forks_count': forksCount,
      'views_count': viewsCount,
      'comments_count': commentsCount,
      'is_public': isPublic,
      'status': status,
      'topics': topics,
      'technologies': technologies,
      'github_url': githubUrl,
      'demo_url': demoUrl,
      'thumbnail_url': thumbnailUrl,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
    };
  }

  /// Creates a copy of this repository with optional overrides
  Repository copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    String? longDescription,
    String? language,
    int? starsCount,
    int? forksCount,
    int? stars, // Backward compatible alias for starsCount
    int? forks, // Backward compatible alias for forksCount
    int? viewsCount,
    int? commentsCount,
    bool? isPublic,
    String? status,
    List<String>? topics,
    List<String>? technologies,
    String? githubUrl,
    String? demoUrl,
    String? thumbnailUrl,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? ownerName,
    String? ownerAvatar,
  }) {
    return Repository(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      longDescription: longDescription ?? this.longDescription,
      language: language ?? this.language,
      starsCount: stars ?? starsCount ?? this.starsCount,
      forksCount: forks ?? forksCount ?? this.forksCount,
      viewsCount: viewsCount ?? this.viewsCount,
      commentsCount: commentsCount ?? this.commentsCount,
      isPublic: isPublic ?? this.isPublic,
      status: status ?? this.status,
      topics: topics ?? List.from(this.topics),
      technologies: technologies ?? List.from(this.technologies),
      githubUrl: githubUrl ?? this.githubUrl,
      demoUrl: demoUrl ?? this.demoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      ownerName: ownerName ?? this.ownerName,
      ownerAvatar: ownerAvatar ?? this.ownerAvatar,
    );
  }

  /// Get status display text
  String get statusLabel {
    switch (status) {
      case 'idea':
        return 'Idea';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'archived':
        return 'Archived';
      default:
        return 'In Progress';
    }
  }

  /// Get formatted last updated text
  String get lastUpdatedText {
    if (updatedAt == null) return 'Unknown';
    
    final diff = DateTime.now().difference(updatedAt!);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
    return '${(diff.inDays / 365).floor()}y ago';
  }

  /// Check if project is active (not archived)
  bool get isActive => status != 'archived';

  /// Check if project is completed
  bool get isCompleted => status == 'completed';

  @override
  String toString() => 'Repository(id: $id, name: $name)';
}

/// Project collaborator model
class ProjectCollaborator {
  final String? id;
  final String projectId;
  final String userId;
  final String role; // 'owner', 'admin', 'contributor', 'viewer'
  final DateTime? joinedAt;
  
  // User info (populated from join)
  final String? userName;
  final String? userAvatar;
  final String? userEmail;

  ProjectCollaborator({
    this.id,
    required this.projectId,
    required this.userId,
    this.role = 'contributor',
    this.joinedAt,
    this.userName,
    this.userAvatar,
    this.userEmail,
  });

  factory ProjectCollaborator.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    
    return ProjectCollaborator(
      id: json['id'] as String?,
      projectId: json['project_id'] as String,
      userId: json['user_id'] as String,
      role: json['role'] as String? ?? 'contributor',
      joinedAt: json['joined_at'] != null 
          ? DateTime.parse(json['joined_at'] as String)
          : null,
      userName: user?['full_name'] as String?,
      userAvatar: user?['avatar_url'] as String?,
      userEmail: user?['email'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'project_id': projectId,
      'user_id': userId,
      'role': role,
    };
  }

  /// Get role display text
  String get roleLabel {
    switch (role) {
      case 'owner':
        return 'Owner';
      case 'admin':
        return 'Admin';
      case 'contributor':
        return 'Contributor';
      case 'viewer':
        return 'Viewer';
      default:
        return 'Contributor';
    }
  }

  /// Check if collaborator can edit project
  bool get canEdit => role == 'owner' || role == 'admin' || role == 'contributor';

  /// Check if collaborator can manage other collaborators
  bool get canManageCollaborators => role == 'owner' || role == 'admin';
}

