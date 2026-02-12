import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/post.dart';
import '../models/profile.dart';
import '../services/theme_service.dart';
import '../services/supabase_service.dart';
import 'user_profile_view_screen.dart';
import 'profile_screen.dart';

/// Explore Screen - Social Feed
/// A LinkedIn-style feed where students can post, react, comment, and repost.
class ExploreScreen extends StatefulWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;
  
  const ExploreScreen({super.key, this.scaffoldKey});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final List<Post> _posts = [];
  final Set<String> _likedPosts = {};
  bool _isLoading = true;
  bool _isPosting = false;
  final TextEditingController _postController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<XFile> _selectedImages = [];
  final ImagePicker _imagePicker = ImagePicker();
  Profile? _currentUserProfile;

  @override
  void initState() {
    super.initState();
    _loadPosts();
    _loadCurrentUserProfile();
  }

  Future<void> _loadCurrentUserProfile() async {
    try {
      final profileData = await SupabaseService.getProfile();
      if (profileData != null && mounted) {
        setState(() => _currentUserProfile = Profile.fromJson(profileData));
      }
    } catch (e) {
      debugPrint('Error loading current user profile: $e');
    }
  }

  @override
  void dispose() {
    _postController.dispose();
    _titleController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPosts() async {
    setState(() => _isLoading = true);

    try {
      final postsData = await SupabaseService.getPosts();
      final currentUserId = SupabaseService.userId;
      
      if (mounted) {
        final posts = postsData.map((p) => Post.fromJson(p, currentUserId: currentUserId)).toList();
        
        // Batch fetch liked posts (fixes N+1 query)
        final postIds = posts.where((p) => p.id != null).map((p) => p.id!).toList();
        final likedIds = await SupabaseService.getLikedPostIds(postIds);
        _likedPosts.clear();
        _likedPosts.addAll(likedIds);
        
        setState(() {
          _posts.clear();
          _posts.addAll(posts);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _createPost() async {
    if (_postController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter some content'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() => _isPosting = true);

    try {
      // Upload images first
      List<String> imageUrls = [];
      for (final image in _selectedImages) {
        final bytes = await image.readAsBytes();
        final url = await SupabaseService.uploadPostImage(bytes, image.name);
        if (url != null) {
          imageUrls.add(url);
        }
      }

      final result = await SupabaseService.createPost(
        title: _titleController.text.trim().isEmpty ? null : _titleController.text.trim(),
        content: _postController.text.trim(),
        images: imageUrls,
      );

      if (result != null && mounted) {
        _postController.clear();
        _titleController.clear();
        _selectedImages = [];
        await _loadPosts();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Post shared successfully!'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to post. Please try again.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().length > 100 ? '${e.toString().substring(0, 100)}...' : e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  Future<void> _toggleLike(Post post) async {
    if (post.id == null) return;

    final isLiked = _likedPosts.contains(post.id);
    
    setState(() {
      if (isLiked) {
        _likedPosts.remove(post.id);
      } else {
        _likedPosts.add(post.id!);
      }
    });

    try {
      if (isLiked) {
        await SupabaseService.unlikePost(post.id!);
      } else {
        await SupabaseService.likePost(post.id!);
      }
    } catch (e) {
      // Revert on error
      setState(() {
        if (isLiked) {
          _likedPosts.add(post.id!);
        } else {
          _likedPosts.remove(post.id);
        }
      });
    }
  }

  void _showPostOptions(Post post, bool isDark) {
    final isMyPost = post.userId == SupabaseService.userId;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              if (isMyPost) ...[
                ListTile(
                  leading: Icon(
                    Icons.edit_rounded,
                    color: AppColors.primaryBlue,
                  ),
                  title: Text(
                    'Edit Post',
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.darkText,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showEditPostSheet(post);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.delete_rounded,
                    color: Colors.red,
                  ),
                  title: const Text(
                    'Delete Post',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDeletePost(post);
                  },
                ),
              ] else ...[
                ListTile(
                  leading: Icon(
                    Icons.report_outlined,
                    color: Colors.orange,
                  ),
                  title: Text(
                    'Report Post',
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.darkText,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Report feature coming soon'),
                        backgroundColor: Colors.orange,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  },
                ),
              ],
              ListTile(
                leading: Icon(
                  Icons.share_rounded,
                  color: isDark ? Colors.white70 : AppColors.darkText,
                ),
                title: Text(
                  'Share Post',
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.darkText,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Share feature coming soon'),
                      backgroundColor: AppColors.primaryBlue,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showEditPostSheet(Post post) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final editTitleController = TextEditingController(text: post.title ?? '');
    final editContentController = TextEditingController(text: post.content);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(20),
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
                Text(
                  'Edit Post',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: editTitleController,
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.darkText,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Title (optional)',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white38 : AppColors.darkText.withValues(alpha: 0.4),
                    ),
                    filled: true,
                    fillColor: isDark 
                        ? AppColors.darkBackground 
                        : AppColors.lightBlue.withValues(alpha: 0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: editContentController,
                  maxLines: 4,
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.darkText,
                  ),
                  decoration: InputDecoration(
                    hintText: "What's on your mind?",
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white38 : AppColors.darkText.withValues(alpha: 0.4),
                    ),
                    filled: true,
                    fillColor: isDark 
                        ? AppColors.darkBackground 
                        : AppColors.lightBlue.withValues(alpha: 0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (editContentController.text.trim().isEmpty) return;
                      
                      try {
                        await SupabaseService.updatePost(
                          postId: post.id!,
                          title: editTitleController.text.trim().isEmpty 
                              ? null 
                              : editTitleController.text.trim(),
                          content: editContentController.text.trim(),
                        );
                        
                        if (mounted) {
                          Navigator.pop(context);
                          _loadPosts();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Post updated successfully!'),
                              backgroundColor: const Color(0xFF10B981),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Save Changes',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDeletePost(Post post) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        title: Text(
          'Delete Post?',
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.darkText,
          ),
        ),
        content: Text(
          'This action cannot be undone. Are you sure you want to delete this post?',
          style: TextStyle(
            color: isDark ? Colors.white70 : AppColors.darkText.withValues(alpha: 0.7),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? Colors.white54 : AppColors.darkText.withValues(alpha: 0.5),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await SupabaseService.deletePost(post.id!);
                _loadPosts();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Post deleted'),
                      backgroundColor: Colors.orange,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showCommentSheet(Post post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CommentSheet(post: post),
    ).then((_) {
      // Refresh posts when comment sheet closes to update counts
      _loadPosts();
    });
  }

  void _showCreatePostSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
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
                      Text(
                        'Create Post',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppColors.darkText,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Title Field
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? Colors.white12 : AppColors.cardBorder,
                          ),
                        ),
                        child: TextField(
                          controller: _titleController,
                          style: TextStyle(
                            color: isDark ? Colors.white : AppColors.darkText,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Title (optional)',
                            hintStyle: TextStyle(
                              color: isDark ? Colors.white38 : AppColors.darkText.withValues(alpha: 0.4),
                              fontWeight: FontWeight.normal,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Content Field
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? Colors.white12 : AppColors.cardBorder,
                          ),
                        ),
                        child: TextField(
                          controller: _postController,
                          maxLines: 5,
                          style: TextStyle(
                            color: isDark ? Colors.white : AppColors.darkText,
                          ),
                          decoration: InputDecoration(
                            hintText: 'What\'s on your mind? Share your thoughts, achievements, or questions...',
                            hintStyle: TextStyle(
                              color: isDark ? Colors.white38 : AppColors.darkText.withValues(alpha: 0.4),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Image Picker
                      Row(
                        children: [
                          IconButton(
                            onPressed: () async {
                              final images = await _imagePicker.pickMultiImage();
                              if (images.isNotEmpty) {
                                setSheetState(() {
                                  _selectedImages = images.take(4).toList();
                                });
                                setState(() {});
                              }
                            },
                            icon: Icon(
                              Icons.image_rounded,
                              color: AppColors.primaryBlue,
                            ),
                            tooltip: 'Add images',
                          ),
                          Text(
                            _selectedImages.isEmpty
                                ? 'Add images (up to 4)'
                                : '${_selectedImages.length} image(s) selected',
                            style: TextStyle(
                              color: isDark ? Colors.white54 : AppColors.darkText.withValues(alpha: 0.6),
                              fontSize: 13,
                            ),
                          ),
                          if (_selectedImages.isNotEmpty) ...[
                            const Spacer(),
                            TextButton(
                              onPressed: () {
                                setSheetState(() {
                                  _selectedImages = [];
                                });
                                setState(() {});
                              },
                              child: Text(
                                'Clear',
                                style: TextStyle(color: Colors.red[400]),
                              ),
                            ),
                          ],
                        ],
                      ),
                      
                      // Image Preview
                      if (_selectedImages.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 80,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _selectedImages.length,
                            itemBuilder: (context, index) {
                              return FutureBuilder<Uint8List>(
                                future: _selectedImages[index].readAsBytes(),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) {
                                    return Container(
                                      width: 80,
                                      height: 80,
                                      margin: const EdgeInsets.only(right: 8),
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.white12 : Colors.grey[200],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Center(
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                    );
                                  }
                                  return Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    child: Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.memory(
                                            snapshot.data!,
                                            width: 80,
                                            height: 80,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        Positioned(
                                          top: 4,
                                          right: 4,
                                          child: GestureDetector(
                                            onTap: () {
                                              setSheetState(() {
                                                _selectedImages.removeAt(index);
                                              });
                                              setState(() {});
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: Colors.black54,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: const Icon(
                                                Icons.close_rounded,
                                                size: 14,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isPosting
                                  ? null
                                  : () {
                                      Navigator.pop(context);
                                      _createPost();
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryBlue,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isPosting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text(
                                      'Post',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.menu_rounded,
            color: isDark ? Colors.white : AppColors.darkText,
          ),
          onPressed: () => widget.scaffoldKey?.currentState?.openDrawer(),
        ),
        title: Text(
          'Feed',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppColors.darkText,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        actions: [
          // Profile avatar icon for quick navigation
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileScreen(
                    profile: _currentUserProfile ?? Profile(),
                    onProfileUpdate: (profile) {
                      setState(() => _currentUserProfile = profile);
                    },
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: _currentUserProfile?.avatarUrl != null
                  ? CircleAvatar(
                      radius: 18,
                      backgroundImage: NetworkImage(_currentUserProfile!.avatarUrl!),
                    )
                  : CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.primaryBlue.withOpacity(0.2),
                      child: Icon(
                        Icons.person_rounded,
                        size: 20,
                        color: isDark ? Colors.white70 : AppColors.primaryBlue,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadPosts,
        color: AppColors.primaryBlue,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
            : _posts.isEmpty
                ? _buildEmptyState(isDark)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _posts.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _buildCreatePostCard(isDark);
                      }
                      return _buildPostCard(_posts[index - 1], isDark);
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreatePostSheet,
        backgroundColor: AppColors.primaryBlue,
        child: const Icon(Icons.edit_rounded, color: Colors.black),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return ListView(
      children: [
        _buildCreatePostCard(isDark),
        const SizedBox(height: 100),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.dynamic_feed_rounded,
                  size: 56,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'No posts yet',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.darkText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Be the first to share something!',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white54 : AppColors.darkText.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCreatePostCard(bool isDark) {
    final userInitial = (_currentUserProfile?.fullName.isNotEmpty ?? false)
        ? _currentUserProfile!.fullName[0].toUpperCase()
        : '?';
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : AppColors.cardBorder,
        ),
      ),
      child: GestureDetector(
        onTap: _showCreatePostSheet,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _currentUserProfile?.avatarUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        _currentUserProfile!.avatarUrl!,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Text(
                              userInitial,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  : Center(
                      child: Text(
                        userInitial,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? Colors.white12 : AppColors.cardBorder,
                  ),
                ),
                child: Text(
                  'Share your thoughts...',
                  style: TextStyle(
                    color: isDark ? Colors.white38 : AppColors.darkText.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard(Post post, bool isDark) {
    final isLiked = _likedPosts.contains(post.id);
    final timeAgo = _getTimeAgo(post.createdAt);
    
    // For simple reposts (not quote reposts), show original post content
    final isSimpleRepost = post.isRepost && !post.isQuoteRepost && post.originalPost != null;
    final displayPost = isSimpleRepost ? post.originalPost! : post;
    
    final authorInitial = (displayPost.authorName?.isNotEmpty ?? false)
        ? displayPost.authorName![0].toUpperCase()
        : '?';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : AppColors.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Repost header if this is a simple repost
          if (isSimpleRepost) ...[
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.repeat_rounded,
                    size: 16,
                    color: isDark ? Colors.white54 : AppColors.darkText.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${post.authorName ?? 'Someone'} reposted',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white54 : AppColors.darkText.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
          ],
          
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar - tappable to view profile
                GestureDetector(
                  onTap: () => _navigateToProfile(displayPost.authorId, displayPost.authorName, displayPost.authorAvatar),
                  child: displayPost.authorAvatar != null && displayPost.authorAvatar!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            displayPost.authorAvatar!,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(authorInitial, isDark),
                          ),
                        )
                      : _buildAvatarPlaceholder(authorInitial, isDark),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _navigateToProfile(displayPost.authorId, displayPost.authorName, displayPost.authorAvatar),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayPost.authorName ?? 'Unknown User',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppColors.darkText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          timeAgo,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white38 : AppColors.darkText.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _showPostOptions(post, isDark),
                  icon: Icon(
                    Icons.more_horiz_rounded,
                    color: isDark ? Colors.white38 : AppColors.darkText.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),

          // Title (if present) - use displayPost for simple reposts
          if (displayPost.title != null && displayPost.title!.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                displayPost.title!,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.darkText,
                ),
              ),
            ),
            const SizedBox(height: 6),
          ],

          // Content - use displayPost for simple reposts
          if (displayPost.content.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                displayPost.content,
                style: TextStyle(
                  fontSize: 15,
                  color: isDark ? Colors.white.withValues(alpha: 0.87) : AppColors.darkText,
                  height: 1.4,
                ),
              ),
            ),
          ],

          // Quote repost - show original post
          if (post.isQuoteRepost && post.originalPost != null) ...[
            const SizedBox(height: 12),
            _buildQuotedPost(post.originalPost!, isDark),
          ],

          // Images (if any) - use displayPost for simple reposts
          if (displayPost.images.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: displayPost.images.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.only(right: index < displayPost.images.length - 1 ? 8 : 0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        displayPost.images[index],
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],

          // Stats
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (post.likesCount > 0) ...[
                  Icon(
                    Icons.thumb_up_rounded,
                    size: 14,
                    color: AppColors.primaryBlue,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${post.likesCount}',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white54 : AppColors.darkText.withValues(alpha: 0.6),
                    ),
                  ),
                  const Spacer(),
                ],
                if (post.commentsCount > 0 || post.repostsCount > 0) ...[
                  if (post.likesCount == 0) const Spacer(),
                  Text(
                    '${post.commentsCount > 0 ? '${post.commentsCount} comments' : ''}${post.commentsCount > 0 && post.repostsCount > 0 ? ' • ' : ''}${post.repostsCount > 0 ? '${post.repostsCount} reposts' : ''}',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white54 : AppColors.darkText.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Divider
          Container(
            height: 1,
            color: isDark ? Colors.white12 : AppColors.cardBorder,
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: isLiked ? Icons.thumb_up_rounded : Icons.thumb_up_outlined,
                    label: 'Like',
                    isActive: isLiked,
                    onTap: () => _toggleLike(post),
                    isDark: isDark,
                  ),
                ),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.comment_outlined,
                    label: 'Comment',
                    onTap: () => _showCommentSheet(post),
                    isDark: isDark,
                  ),
                ),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.repeat_rounded,
                    label: 'Repost',
                    onTap: () => _showRepostDialog(post),
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarPlaceholder(String initial, bool isDark) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.primaryBlue : AppColors.darkText,
          ),
        ),
      ),
    );
  }

  Widget _buildQuotedPost(Post originalPost, bool isDark) {
    final originalAuthorInitial = (originalPost.authorName?.isNotEmpty ?? false)
        ? originalPost.authorName![0].toUpperCase()
        : '?';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white12 : AppColors.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Original author header
          Row(
            children: [
              GestureDetector(
                onTap: () => _navigateToProfile(
                  originalPost.authorId,
                  originalPost.authorName,
                  originalPost.authorAvatar,
                ),
                child: originalPost.authorAvatar != null && originalPost.authorAvatar!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          originalPost.authorAvatar!,
                          width: 32,
                          height: 32,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                originalAuthorInitial,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppColors.primaryBlue : AppColors.darkText,
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    : Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            originalAuthorInitial,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.primaryBlue : AppColors.darkText,
                            ),
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => _navigateToProfile(
                    originalPost.authorId,
                    originalPost.authorName,
                    originalPost.authorAvatar,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        originalPost.authorName ?? 'Unknown User',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppColors.darkText,
                        ),
                      ),
                      Text(
                        _getTimeAgo(originalPost.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white38 : AppColors.darkText.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Original post title if present
          if (originalPost.title != null && originalPost.title!.isNotEmpty) ...[
            Text(
              originalPost.title!,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.darkText,
              ),
            ),
            const SizedBox(height: 4),
          ],
          
          // Original post content
          Text(
            originalPost.content.length > 150
                ? '${originalPost.content.substring(0, 150)}...'
                : originalPost.content,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white70 : AppColors.darkText.withValues(alpha: 0.8),
              height: 1.4,
            ),
          ),
          
          // Original post images thumbnail
          if (originalPost.images.isNotEmpty) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                originalPost.images.first,
                height: 80,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _navigateToProfile(String? userId, String? userName, String? userAvatar) {
    if (userId == null) return;
    
    // Don't navigate to own profile
    if (userId == SupabaseService.userId) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileViewScreen(
          userId: userId,
          userName: userName,
          userAvatar: userAvatar,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
    bool isActive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive
                  ? AppColors.primaryBlue
                  : (isDark ? Colors.white54 : AppColors.darkText.withValues(alpha: 0.6)),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isActive
                    ? AppColors.primaryBlue
                    : (isDark ? Colors.white54 : AppColors.darkText.withValues(alpha: 0.6)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRepostDialog(Post post) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
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
            Text(
              'Share Post',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.darkText,
              ),
            ),
            const SizedBox(height: 20),
            
            // Repost option
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.repeat_rounded,
                  color: AppColors.primaryBlue,
                ),
              ),
              title: Text(
                'Repost',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.darkText,
                ),
              ),
              subtitle: Text(
                'Share to your feed instantly',
                style: TextStyle(
                  color: isDark ? Colors.white54 : AppColors.darkText.withValues(alpha: 0.6),
                  fontSize: 13,
                ),
              ),
              onTap: () async {
                Navigator.pop(context);
                if (post.id != null) {
                  final result = await SupabaseService.repost(post.id!);
                  if (result != null) {
                    await _loadPosts();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Reposted successfully!'),
                          backgroundColor: const Color(0xFF10B981),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    }
                  }
                }
              },
            ),
            
            const SizedBox(height: 8),
            
            // Quote repost option
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.format_quote_rounded,
                  color: Colors.orange,
                ),
              ),
              title: Text(
                'Quote Repost',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.darkText,
                ),
              ),
              subtitle: Text(
                'Add your thoughts to the post',
                style: TextStyle(
                  color: isDark ? Colors.white54 : AppColors.darkText.withValues(alpha: 0.6),
                  fontSize: 13,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _showQuoteRepostSheet(post);
              },
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showQuoteRepostSheet(Post post) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final quoteController = TextEditingController();
    bool isPosting = false;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(20),
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
                  Text(
                    'Quote Repost',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Quote text field
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.white12 : AppColors.cardBorder,
                      ),
                    ),
                    child: TextField(
                      controller: quoteController,
                      maxLines: 3,
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.darkText,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Add your thoughts...',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.white38 : AppColors.darkText.withValues(alpha: 0.4),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Original post preview
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? Colors.white12 : AppColors.cardBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 50,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                post.authorName ?? 'Unknown',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: isDark ? Colors.white : AppColors.darkText,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                post.content.length > 100
                                    ? '${post.content.substring(0, 100)}...'
                                    : post.content,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white54 : AppColors.darkText.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isPosting
                              ? null
                              : () async {
                                  if (quoteController.text.trim().isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text('Please add your thoughts'),
                                        backgroundColor: Colors.orange,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    );
                                    return;
                                  }
                                  
                                  setSheetState(() => isPosting = true);
                                  
                                  if (post.id != null) {
                                    final result = await SupabaseService.quoteRepost(
                                      post.id!,
                                      quoteController.text.trim(),
                                    );
                                    
                                    if (mounted) Navigator.pop(context);
                                    
                                    if (result != null) {
                                      await _loadPosts();
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: const Text('Quote reposted successfully!'),
                                            backgroundColor: const Color(0xFF10B981),
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                        );
                                      }
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isPosting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text(
                                  'Quote Repost',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _getTimeAgo(DateTime? dateTime) {
    if (dateTime == null) return 'Just now';
    
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}

/// Comment Sheet Widget
class _CommentSheet extends StatefulWidget {
  final Post post;

  const _CommentSheet({required this.post});

  @override
  State<_CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends State<_CommentSheet> {
  final List<PostComment> _comments = [];
  final TextEditingController _commentController = TextEditingController();
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    if (widget.post.id == null) return;

    setState(() => _isLoading = true);
    
    try {
      final commentsData = await SupabaseService.getPostComments(widget.post.id!);
      if (mounted) {
        setState(() {
          _comments.clear();
          _comments.addAll(commentsData.map((c) => PostComment.fromJson(c)));
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty || widget.post.id == null) return;

    setState(() => _isSubmitting = true);

    try {
      await SupabaseService.addPostComment(
        postId: widget.post.id!,
        content: _commentController.text.trim(),
      );
      
      _commentController.clear();
      await _loadComments();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post comment: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.all(12),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : AppColors.cardBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      'Comments',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.darkText,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${_comments.length})',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white54 : AppColors.darkText.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Comments List
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
                    : _comments.isEmpty
                        ? Center(
                            child: Text(
                              'No comments yet. Be the first!',
                              style: TextStyle(
                                color: isDark ? Colors.white54 : AppColors.darkText.withValues(alpha: 0.5),
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _comments.length,
                            itemBuilder: (context, index) {
                              return _buildCommentItem(_comments[index], isDark);
                            },
                          ),
              ),

              // Comment Input
              Container(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 12,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 12,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                  border: Border(
                    top: BorderSide(
                      color: isDark ? Colors.white12 : AppColors.cardBorder,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isDark ? Colors.white12 : AppColors.cardBorder,
                          ),
                        ),
                        child: TextField(
                          controller: _commentController,
                          style: TextStyle(
                            color: isDark ? Colors.white : AppColors.darkText,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Write a comment...',
                            hintStyle: TextStyle(
                              color: isDark ? Colors.white38 : AppColors.darkText.withValues(alpha: 0.4),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _isSubmitting ? null : _submitComment,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: _isSubmitting
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : const Icon(
                                Icons.send_rounded,
                                color: Colors.black,
                                size: 20,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommentItem(PostComment comment, bool isDark) {
    final initial = (comment.authorName?.isNotEmpty ?? false)
        ? comment.authorName![0].toUpperCase()
        : '?';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          comment.authorAvatar != null && comment.authorAvatar!.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    comment.authorAvatar!,
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildSmallAvatar(initial, isDark),
                  ),
                )
              : _buildSmallAvatar(initial, isDark),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    comment.authorName ?? 'Unknown User',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    comment.content,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white.withValues(alpha: 0.87) : AppColors.darkText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallAvatar(String initial, bool isDark) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.primaryBlue : AppColors.darkText,
          ),
        ),
      ),
    );
  }
}
