/// Post model for social feed
/// Represents a post in the explore/feed section
class Post {
  final String? id;
  final String userId;
  final String? title;
  final String content;
  final List<String> images;
  final String? originalPostId; // For reposts
  final String? quoteText; // For quote reposts
  final String? reposterId; // Who reposted (for regular reposts)
  final int likesCount;
  final int commentsCount;
  final int repostsCount;
  final bool isRepost;
  final bool isQuoteRepost;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Author info (populated from join)
  final String? authorName;
  final String? authorAvatar;
  final String? authorBio;
  
  // Reposter info (for regular reposts)
  final String? reposterName;
  final String? reposterAvatar;

  // Original post info (for reposts)
  final Post? originalPost;

  // Current user's interaction state
  final bool isLikedByMe;
  final bool isRepostedByMe;

  /// Getter for author ID (alias for userId for clarity)
  String? get authorId => userId.isNotEmpty ? userId : null;

  Post({
    this.id,
    required this.userId,
    this.title,
    required this.content,
    this.images = const [],
    this.originalPostId,
    this.quoteText,
    this.reposterId,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.repostsCount = 0,
    this.isRepost = false,
    this.isQuoteRepost = false,
    this.createdAt,
    this.updatedAt,
    this.authorName,
    this.authorAvatar,
    this.authorBio,
    this.reposterName,
    this.reposterAvatar,
    this.originalPost,
    this.isLikedByMe = false,
    this.isRepostedByMe = false,
  });

  factory Post.fromJson(Map<String, dynamic> json, {String? currentUserId}) {
    final profiles = json['profiles'] as Map<String, dynamic>?;
    final reposterProfile = json['reposter'] as Map<String, dynamic>?;
    final likes = json['post_likes'] as List<dynamic>? ?? [];
    final reposts = json['post_reposts'] as List<dynamic>? ?? [];
    final originalPostData = json['original_post'] as Map<String, dynamic>?;

    Post? originalPost;
    if (originalPostData != null) {
      originalPost = Post.fromJson(originalPostData, currentUserId: currentUserId);
    }

    return Post(
      id: json['id'] as String?,
      userId: json['user_id'] as String? ?? '',
      title: json['title'] as String?,
      content: json['content'] as String? ?? '',
      images: (json['images'] as List<dynamic>?)?.cast<String>() ?? [],
      originalPostId: json['original_post_id'] as String?,
      quoteText: json['quote_text'] as String?,
      reposterId: json['reposter_id'] as String?,
      likesCount: json['likes_count'] as int? ?? 0,
      commentsCount: json['comments_count'] as int? ?? 0,
      repostsCount: json['reposts_count'] as int? ?? 0,
      isRepost: json['is_repost'] as bool? ?? false,
      isQuoteRepost: json['is_quote_repost'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
      authorName: profiles?['full_name'] as String?,
      authorAvatar: profiles?['avatar_url'] as String?,
      authorBio: profiles?['bio'] as String?,
      reposterName: reposterProfile?['full_name'] as String?,
      reposterAvatar: reposterProfile?['avatar_url'] as String?,
      originalPost: originalPost,
      isLikedByMe: currentUserId != null &&
          likes.any((like) => like['user_id'] == currentUserId),
      isRepostedByMe: currentUserId != null &&
          reposts.any((repost) => repost['user_id'] == currentUserId),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      if (title != null) 'title': title,
      'content': content,
      'images': images,
      if (originalPostId != null) 'original_post_id': originalPostId,
      if (quoteText != null) 'quote_text': quoteText,
      if (reposterId != null) 'reposter_id': reposterId,
      'is_repost': isRepost,
      'is_quote_repost': isQuoteRepost,
    };
  }

  Post copyWith({
    String? id,
    String? userId,
    String? title,
    String? content,
    List<String>? images,
    String? originalPostId,
    String? quoteText,
    String? reposterId,
    int? likesCount,
    int? commentsCount,
    int? repostsCount,
    bool? isRepost,
    bool? isQuoteRepost,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? authorName,
    String? authorAvatar,
    String? authorBio,
    String? reposterName,
    String? reposterAvatar,
    Post? originalPost,
    bool? isLikedByMe,
    bool? isRepostedByMe,
  }) {
    return Post(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      content: content ?? this.content,
      images: images ?? this.images,
      originalPostId: originalPostId ?? this.originalPostId,
      quoteText: quoteText ?? this.quoteText,
      reposterId: reposterId ?? this.reposterId,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      repostsCount: repostsCount ?? this.repostsCount,
      isRepost: isRepost ?? this.isRepost,
      isQuoteRepost: isQuoteRepost ?? this.isQuoteRepost,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      authorBio: authorBio ?? this.authorBio,
      reposterName: reposterName ?? this.reposterName,
      reposterAvatar: reposterAvatar ?? this.reposterAvatar,
      originalPost: originalPost ?? this.originalPost,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
      isRepostedByMe: isRepostedByMe ?? this.isRepostedByMe,
    );
  }
}

/// Comment model for post comments
class PostComment {
  final String? id;
  final String postId;
  final String userId;
  final String content;
  final int likesCount;
  final DateTime? createdAt;

  // Author info
  final String? authorName;
  final String? authorAvatar;
  final bool isLikedByMe;

  PostComment({
    this.id,
    required this.postId,
    required this.userId,
    required this.content,
    this.likesCount = 0,
    this.createdAt,
    this.authorName,
    this.authorAvatar,
    this.isLikedByMe = false,
  });

  factory PostComment.fromJson(Map<String, dynamic> json, {String? currentUserId}) {
    final profiles = json['profiles'] as Map<String, dynamic>?;
    final likes = json['comment_likes'] as List<dynamic>? ?? [];

    return PostComment(
      id: json['id'] as String?,
      postId: json['post_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      content: json['content'] as String? ?? '',
      likesCount: json['likes_count'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      authorName: profiles?['full_name'] as String?,
      authorAvatar: profiles?['avatar_url'] as String?,
      isLikedByMe: currentUserId != null &&
          likes.any((like) => like['user_id'] == currentUserId),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'post_id': postId,
      'user_id': userId,
      'content': content,
    };
  }
}
