/// Profile model class
/// Stores the student's personal information, bio, skills, and projects.
/// Enhanced for full-stack implementation with additional fields.
class Profile {
  final String? id;
  String fullName;
  String email;
  String bio;
  String pronouns;
  String? avatarUrl;
  String? coverPhotoUrl;
  String socialLink;
  String facebookUsername;
  String linkedinUsername;
  String githubUsername;
  String? websiteUrl;
  String? location;
  String? yearLevel;
  String? course;
  List<String> skills;
  List<String> projects; // List of project names for backward compatibility
  int followersCount;
  int followingCount;
  int projectsCount;
  int profileViews;
  bool isVerified;
  bool isOnline;
  DateTime? lastSeen;
  DateTime? createdAt;
  DateTime? updatedAt;

  Profile({
    this.id,
    this.fullName = 'New User',
    this.email = '',
    this.bio = '',
    this.pronouns = '',
    this.avatarUrl,
    this.coverPhotoUrl,
    this.socialLink = '',
    this.facebookUsername = '',
    this.linkedinUsername = '',
    this.githubUsername = '',
    this.websiteUrl,
    this.location,
    this.yearLevel,
    this.course,
    List<String>? skills,
    List<String>? projects,
    this.followersCount = 0,
    this.followingCount = 0,
    this.projectsCount = 0,
    this.profileViews = 0,
    this.isVerified = false,
    this.isOnline = false,
    this.lastSeen,
    this.createdAt,
    this.updatedAt,
  }) : skills = skills ?? [],
       projects = projects ?? [];

  /// Create Profile from Supabase JSON response
  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String?,
      fullName: json['full_name'] as String? ?? 'New User',
      email: json['email'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      pronouns: json['pronouns'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      coverPhotoUrl: json['cover_photo_url'] as String?,
      socialLink: json['social_link'] as String? ?? '',
      facebookUsername: json['facebook_username'] as String? ?? '',
      linkedinUsername: json['linkedin_username'] as String? ?? '',
      githubUsername: json['github_username'] as String? ?? '',
      websiteUrl: json['website_url'] as String?,
      location: json['location'] as String?,
      yearLevel: json['year_level'] as String?,
      course: json['course'] as String?,
      skills: (json['skills'] as List<dynamic>?)?.cast<String>() ?? [],
      projects: (json['projects'] as List<dynamic>?)?.cast<String>() ?? [],
      followersCount: json['followers_count'] as int? ?? 0,
      followingCount: json['following_count'] as int? ?? 0,
      projectsCount: json['projects_count'] as int? ?? 0,
      profileViews: json['profile_views'] as int? ?? 0,
      isVerified: json['is_verified'] as bool? ?? false,
      isOnline: json['is_online'] as bool? ?? false,
      lastSeen: json['last_seen'] != null
          ? DateTime.parse(json['last_seen'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Convert Profile to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'full_name': fullName,
      'email': email,
      'bio': bio,
      'pronouns': pronouns,
      'avatar_url': avatarUrl,
      'cover_photo_url': coverPhotoUrl,
      'social_link': socialLink,
      'facebook_username': facebookUsername,
      'linkedin_username': linkedinUsername,
      'github_username': githubUsername,
      'website_url': websiteUrl,
      'location': location,
      'year_level': yearLevel,
      'course': course,
      'skills': skills,
      'projects': projects,
      'followers_count': followersCount,
      'following_count': followingCount,
      'projects_count': projectsCount,
      'profile_views': profileViews,
      'is_verified': isVerified,
      'is_online': isOnline,
    };
  }

  /// Creates a copy of this profile with optional overrides
  Profile copyWith({
    String? id,
    String? fullName,
    String? bio,
    String? email,
    String? pronouns,
    String? avatarUrl,
    String? coverPhotoUrl,
    String? socialLink,
    String? facebookUsername,
    String? linkedinUsername,
    String? githubUsername,
    String? websiteUrl,
    String? location,
    String? yearLevel,
    String? course,
    List<String>? skills,
    List<String>? projects,
    int? followersCount,
    int? followingCount,
    int? projectsCount,
    int? profileViews,
    bool? isVerified,
    bool? isOnline,
    DateTime? lastSeen,
  }) {
    return Profile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      bio: bio ?? this.bio,
      email: email ?? this.email,
      pronouns: pronouns ?? this.pronouns,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      coverPhotoUrl: coverPhotoUrl ?? this.coverPhotoUrl,
      socialLink: socialLink ?? this.socialLink,
      facebookUsername: facebookUsername ?? this.facebookUsername,
      linkedinUsername: linkedinUsername ?? this.linkedinUsername,
      githubUsername: githubUsername ?? this.githubUsername,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      location: location ?? this.location,
      yearLevel: yearLevel ?? this.yearLevel,
      course: course ?? this.course,
      skills: skills ?? List.from(this.skills),
      projects: projects ?? List.from(this.projects),
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      projectsCount: projectsCount ?? this.projectsCount,
      profileViews: profileViews ?? this.profileViews,
      isVerified: isVerified ?? this.isVerified,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Get initials from full name
  String get initials {
    final parts = fullName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'U';
  }

  /// Get online status text
  String get statusText {
    if (isOnline) return 'Online';
    if (lastSeen == null) return 'Offline';
    
    final diff = DateTime.now().difference(lastSeen!);
    if (diff.inMinutes < 5) return 'Just now';
    if (diff.inHours < 1) return 'Active ${diff.inMinutes}m ago';
    if (diff.inDays < 1) return 'Active ${diff.inHours}h ago';
    return 'Active ${diff.inDays}d ago';
  }

  /// Check if profile is complete
  bool get isProfileComplete {
    return bio.isNotEmpty && 
           skills.isNotEmpty && 
           (course?.isNotEmpty ?? false);
  }

  @override
  String toString() => 'Profile(id: $id, fullName: $fullName, email: $email)';
}

