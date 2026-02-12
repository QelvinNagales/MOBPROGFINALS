import 'package:flutter/material.dart';
import '../models/repository.dart';
import '../models/project_models.dart';
import '../services/supabase_service.dart';
import '../services/theme_service.dart';
import 'user_profile_view_screen.dart';
import 'add_project_screen.dart';

// Helper to check dark mode
bool _isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;

/// Comprehensive Project Detail Screen
/// Shows full project details with comments, collaboration requests, and interactions
class ProjectDetailScreen extends StatefulWidget {
  final String projectId;
  final Repository? repository; // If already have the data
  
  const ProjectDetailScreen({
    super.key,
    required this.projectId,
    this.repository,
  });

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  Map<String, dynamic>? _projectData;
  List<ProjectComment> _comments = [];
  bool _isLoading = true;
  bool _isStarred = false;
  bool _hasRequestedCollab = false;
  bool _isOwner = false;
  final _commentController = TextEditingController();
  bool _isSubmittingComment = false;
  bool _isRequestingCollab = false;
  final _collabMessageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProjectDetails();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _collabMessageController.dispose();
    super.dispose();
  }

  Future<void> _loadProjectDetails() async {
    setState(() => _isLoading = true);
    
    try {
      // Load project data
      final projectData = await SupabaseService.getProjectById(widget.projectId);
      
      // Check if user has starred this project
      final hasStarred = await SupabaseService.hasStarredProject(widget.projectId);
      
      // Check if user has requested collaboration
      final hasRequested = await SupabaseService.hasRequestedCollaboration(widget.projectId);
      
      // Load comments
      final commentsData = await SupabaseService.getProjectComments(widget.projectId);
      
      // Check if current user is owner
      final currentUserId = SupabaseService.userId;
      final isOwner = projectData?['user_id'] == currentUserId;
      
      // Increment view count if not owner
      if (!isOwner) {
        SupabaseService.incrementProjectViews(widget.projectId);
      }
      
      if (mounted) {
        setState(() {
          _projectData = projectData;
          _isStarred = hasStarred;
          _hasRequestedCollab = hasRequested;
          _isOwner = isOwner;
          _comments = commentsData.map((c) => ProjectComment.fromJson(c)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading project details: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleStar() async {
    final wasStarred = _isStarred;
    setState(() => _isStarred = !_isStarred);
    
    try {
      if (wasStarred) {
        await SupabaseService.unstarProject(widget.projectId);
      } else {
        await SupabaseService.starProject(widget.projectId);
      }
      // Refresh to get updated star count
      final updatedProject = await SupabaseService.getProjectById(widget.projectId);
      if (mounted && updatedProject != null) {
        setState(() {
          _projectData = updatedProject;
        });
      }
    } catch (e) {
      // Revert on error
      setState(() => _isStarred = wasStarred);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;
    
    setState(() => _isSubmittingComment = true);
    
    try {
      final commentData = await SupabaseService.addProjectComment(
        projectId: widget.projectId,
        content: content,
      );
      
      final newComment = ProjectComment.fromJson(commentData);
      
      if (mounted) {
        setState(() {
          _comments.insert(0, newComment);
          _commentController.clear();
          _isSubmittingComment = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmittingComment = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error posting comment: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteComment(String commentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    try {
      await SupabaseService.deleteProjectComment(commentId);
      setState(() {
        _comments.removeWhere((c) => c.id == commentId);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting comment: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showCollaborationDialog() {
    final isDark = _isDark(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Request Collaboration',
          style: TextStyle(color: isDark ? Colors.white : AppColors.darkText),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Send a message to the project owner explaining why you\'d like to collaborate:',
              style: TextStyle(
                color: isDark ? Colors.white70 : AppColors.darkText.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _collabMessageController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'I\'d love to contribute to this project because...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: isDark ? Colors.white10 : AppColors.grey,
              ),
              style: TextStyle(color: isDark ? Colors.white : AppColors.darkText),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white54 : null)),
          ),
          ElevatedButton(
            onPressed: _isRequestingCollab ? null : () async {
              final message = _collabMessageController.text.trim();
              if (message.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a message')),
                );
                return;
              }
              
              Navigator.pop(context);
              await _submitCollaborationRequest(message);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Send Request', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _submitCollaborationRequest(String message) async {
    setState(() => _isRequestingCollab = true);
    
    try {
      final ownerId = _projectData?['user_id'];
      if (ownerId == null) throw Exception('Owner not found');
      
      await SupabaseService.sendCollaborationRequest(
        projectId: widget.projectId,
        ownerId: ownerId,
        message: message,
      );
      
      if (mounted) {
        setState(() {
          _hasRequestedCollab = true;
          _isRequestingCollab = false;
        });
        _collabMessageController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Collaboration request sent!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRequestingCollab = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _isDark(context);
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : AppColors.darkText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Project Details',
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.darkText,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (!_isOwner && _projectData != null)
            IconButton(
              icon: Icon(
                _isStarred ? Icons.star_rounded : Icons.star_border_rounded,
                color: _isStarred ? AppColors.warning : (isDark ? Colors.white54 : AppColors.darkText.withValues(alpha: 0.5)),
              ),
              onPressed: _toggleStar,
            ),
          if (_isOwner && _projectData != null)
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: isDark ? Colors.white : AppColors.darkText),
              color: isDark ? AppColors.darkCard : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (value) {
                if (value == 'edit') {
                  _editProject();
                } else if (value == 'delete') {
                  _deleteProject();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      const Icon(Icons.edit_rounded, size: 20),
                      const SizedBox(width: 12),
                      Text('Edit Project', style: TextStyle(color: isDark ? Colors.white : AppColors.darkText)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(Icons.delete_rounded, size: 20, color: Colors.red),
                      const SizedBox(width: 12),
                      const Text('Delete Project', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _projectData == null
              ? _buildErrorState(isDark)
              : _buildContent(isDark),
    );
  }

  void _editProject() async {
    if (_projectData == null) return;
    
    // Convert project data to Repository object
    final repository = Repository.fromJson(_projectData!);
    
    // Navigate to AddProjectScreen with the existing project
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddProjectScreen(existingProject: repository),
      ),
    );
    
    // Refresh project details if edited
    if (result == true) {
      _loadProjectDetails();
    }
  }

  Future<void> _deleteProject() async {
    final isDark = _isDark(context);
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Project',
          style: TextStyle(color: isDark ? Colors.white : AppColors.darkText),
        ),
        content: Text(
          'Are you sure you want to delete "${_projectData?['name'] ?? 'this project'}"? This action cannot be undone.',
          style: TextStyle(color: isDark ? Colors.white70 : AppColors.darkText.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white54 : null)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    try {
      await SupabaseService.deleteProject(widget.projectId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Project deleted'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context); // Go back after deletion
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting project: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: isDark ? Colors.white38 : AppColors.cardBorder),
          const SizedBox(height: 16),
          Text(
            'Project not found',
            style: TextStyle(
              fontSize: 18,
              color: isDark ? Colors.white70 : AppColors.darkText,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    final profile = _projectData!['profiles'] as Map<String, dynamic>?;
    final ownerName = profile?['full_name'] ?? 'Unknown';
    final ownerAvatar = profile?['avatar_url'];
    final ownerId = profile?['id'];
    final ownerCourse = profile?['course'] ?? '';
    
    final name = _projectData!['name'] ?? 'Untitled';
    final description = _projectData!['description'] ?? 'No description provided';
    final language = _projectData!['language'] ?? 'Unknown';
    final stars = _projectData!['stars_count'] ?? 0;
    final forks = _projectData!['forks_count'] ?? 0;
    final views = _projectData!['views_count'] ?? 0;
    final isPublic = _projectData!['is_public'] ?? true;
    final topics = (_projectData!['topics'] as List<dynamic>?)?.cast<String>() ?? [];
    final screenshots = (_projectData!['screenshots'] as List<dynamic>?)?.cast<String>() ?? [];
    final videoUrl = _projectData!['video_url'];
    final docsUrl = _projectData!['docs_url'];
    final lookingForTeam = _projectData!['looking_for_team'] ?? false;
    final status = _projectData!['status'] ?? 'active';
    final updatedAt = DateTime.tryParse(_projectData!['updated_at'] ?? '');
    
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Owner Card
                _buildOwnerCard(isDark, ownerId, ownerName, ownerAvatar, ownerCourse),
                const SizedBox(height: 20),
                
                // Project Header
                _buildProjectHeader(isDark, name, language, isPublic, status, lookingForTeam),
                const SizedBox(height: 20),
                
                // Stats Row
                _buildStatsRow(isDark, stars, forks, views),
                const SizedBox(height: 20),
                
                // Description
                _buildSection(
                  isDark,
                  'Description',
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 15,
                      color: isDark ? Colors.white : AppColors.darkText,
                      height: 1.6,
                    ),
                  ),
                ),
                
                // Topics
                if (topics.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildSection(
                    isDark,
                    'Topics',
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: topics.map((topic) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          topic,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )).toList(),
                    ),
                  ),
                ],
                
                // Screenshots Gallery
                if (screenshots.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildSection(
                    isDark,
                    'Screenshots',
                    SizedBox(
                      height: 180,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: screenshots.length,
                        itemBuilder: (context, index) => Padding(
                          padding: EdgeInsets.only(right: index < screenshots.length - 1 ? 12 : 0),
                          child: GestureDetector(
                            onTap: () => _showImageViewer(screenshots, index),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                screenshots[index],
                                height: 180,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  height: 180,
                                  width: 240,
                                  color: isDark ? Colors.white12 : AppColors.grey,
                                  child: const Icon(Icons.broken_image, size: 40),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                
                // Links Section
                if (videoUrl != null || docsUrl != null) ...[
                  const SizedBox(height: 20),
                  _buildSection(
                    isDark,
                    'Links',
                    Column(
                      children: [
                        if (videoUrl != null)
                          _buildLinkTile(isDark, Icons.play_circle_outline, 'Demo Video', videoUrl),
                        if (docsUrl != null)
                          _buildLinkTile(isDark, Icons.description_outlined, 'Documentation', docsUrl),
                      ],
                    ),
                  ),
                ],
                
                // Last Updated
                if (updatedAt != null) ...[
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Icon(Icons.update_rounded, size: 16, color: isDark ? Colors.white38 : AppColors.darkText.withValues(alpha: 0.5)),
                      const SizedBox(width: 8),
                      Text(
                        'Last updated: ${_formatDate(updatedAt)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white38 : AppColors.darkText.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ],
                
                // Collaboration Button (if not owner and looking for team)
                if (!_isOwner && lookingForTeam) ...[
                  const SizedBox(height: 24),
                  _buildCollaborationButton(isDark),
                ],
                
                const SizedBox(height: 24),
                Divider(color: isDark ? Colors.white12 : AppColors.cardBorder),
                const SizedBox(height: 16),
                
                // Comments Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Comments (${_comments.length})',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.darkText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Comment Input
                _buildCommentInput(isDark),
              ],
            ),
          ),
        ),
        
        // Comments List
        _comments.isEmpty
            ? SliverToBoxAdapter(child: _buildEmptyCommentsState(isDark))
            : SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildCommentItem(_comments[index], isDark),
                  childCount: _comments.length,
                ),
              ),
        
        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }

  Widget _buildOwnerCard(bool isDark, String? ownerId, String ownerName, String? ownerAvatar, String ownerCourse) {
    final initial = ownerName.isNotEmpty ? ownerName[0].toUpperCase() : '?';
    
    return GestureDetector(
      onTap: ownerId != null ? () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserProfileViewScreen(userId: ownerId),
          ),
        );
      } : null,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.primaryBlue.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.white12 : AppColors.primaryBlue.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            ownerAvatar != null && ownerAvatar.isNotEmpty
                ? CircleAvatar(
                    radius: 24,
                    backgroundImage: NetworkImage(ownerAvatar),
                  )
                : CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.2),
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ownerName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  if (ownerCourse.isNotEmpty)
                    Text(
                      ownerCourse,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white54 : AppColors.darkText.withValues(alpha: 0.6),
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? Colors.white38 : AppColors.primaryBlue.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectHeader(bool isDark, String name, String language, bool isPublic, String status, bool lookingForTeam) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.folder_open_rounded, color: AppColors.warning, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.darkText,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildBadge(
              isPublic ? 'Public' : 'Private',
              isPublic ? Icons.public : Icons.lock,
              isPublic ? AppColors.success : AppColors.warning,
            ),
            _buildBadge(language, Icons.code, AppColors.primaryBlue),
            _buildStatusBadge(status),
            if (lookingForTeam)
              _buildBadge('Looking for Team', Icons.group_add, Colors.purple),
          ],
        ),
      ],
    );
  }

  Widget _buildBadge(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    IconData icon;
    String label;
    
    switch (status.toLowerCase()) {
      case 'completed':
        color = AppColors.success;
        icon = Icons.check_circle_outline;
        label = 'Completed';
        break;
      case 'in_progress':
        color = AppColors.primaryBlue;
        icon = Icons.pending_outlined;
        label = 'In Progress';
        break;
      case 'on_hold':
        color = AppColors.warning;
        icon = Icons.pause_circle_outline;
        label = 'On Hold';
        break;
      default:
        color = Colors.grey;
        icon = Icons.circle_outlined;
        label = 'Active';
    }
    
    return _buildBadge(label, icon, color);
  }

  Widget _buildStatsRow(bool isDark, int stars, int forks, int views) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white12 : AppColors.cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStat(Icons.star_rounded, '$stars', 'Stars', AppColors.warning, isDark),
          Container(width: 1, height: 40, color: isDark ? Colors.white12 : AppColors.cardBorder),
          _buildStat(Icons.call_split_rounded, '$forks', 'Forks', AppColors.primaryBlue, isDark),
          Container(width: 1, height: 40, color: isDark ? Colors.white12 : AppColors.cardBorder),
          _buildStat(Icons.visibility_rounded, '$views', 'Views', AppColors.success, isDark),
        ],
      ),
    );
  }

  Widget _buildStat(IconData icon, String value, String label, Color color, bool isDark) {
    return Column(
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: isDark ? Colors.white : AppColors.darkText,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white54 : AppColors.darkText.withValues(alpha: 0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSection(bool isDark, String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : AppColors.darkText.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 10),
        content,
      ],
    );
  }

  Widget _buildLinkTile(bool isDark, IconData icon, String title, String url) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primaryBlue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primaryBlue, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDark ? Colors.white : AppColors.darkText,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        url,
        style: TextStyle(
          color: AppColors.primaryBlue,
          fontSize: 12,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Icon(
        Icons.open_in_new_rounded,
        size: 18,
        color: isDark ? Colors.white38 : AppColors.darkText.withValues(alpha: 0.4),
      ),
      onTap: () {
        // TODO: Open URL
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Opening: $url')),
        );
      },
    );
  }

  Widget _buildCollaborationButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _hasRequestedCollab || _isRequestingCollab ? null : _showCollaborationDialog,
        icon: Icon(
          _hasRequestedCollab ? Icons.check_circle : Icons.handshake_outlined,
          color: Colors.white,
        ),
        label: Text(
          _hasRequestedCollab
              ? 'Request Sent'
              : _isRequestingCollab
                  ? 'Sending...'
                  : 'Request Collaboration',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _hasRequestedCollab ? AppColors.success : AppColors.primaryBlue,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          disabledBackgroundColor: AppColors.success.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  Widget _buildCommentInput(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white12 : AppColors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              maxLines: 3,
              minLines: 1,
              decoration: InputDecoration(
                hintText: 'Write a comment...',
                hintStyle: TextStyle(
                  color: isDark ? Colors.white38 : AppColors.darkText.withValues(alpha: 0.4),
                ),
                border: InputBorder.none,
              ),
              style: TextStyle(color: isDark ? Colors.white : AppColors.darkText),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _isSubmittingComment ? null : _submitComment,
            icon: _isSubmittingComment
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded),
            color: AppColors.primaryBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCommentsState(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 48,
            color: isDark ? Colors.white24 : AppColors.cardBorder,
          ),
          const SizedBox(height: 12),
          Text(
            'No comments yet',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white54 : AppColors.darkText.withValues(alpha: 0.6),
            ),
          ),
          Text(
            'Be the first to comment!',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white38 : AppColors.darkText.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(ProjectComment comment, bool isDark) {
    final currentUserId = SupabaseService.userId;
    final isMyComment = comment.userId == currentUserId;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? Colors.white12 : AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                comment.userAvatar != null && comment.userAvatar!.isNotEmpty
                    ? CircleAvatar(
                        radius: 16,
                        backgroundImage: NetworkImage(comment.userAvatar!),
                      )
                    : CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.2),
                        child: Text(
                          (comment.userName ?? '').isNotEmpty ? comment.userName![0].toUpperCase() : '?',
                          style: const TextStyle(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment.userName ?? 'Unknown',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppColors.darkText,
                        ),
                      ),
                      Text(
                        comment.timeAgo,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white38 : AppColors.darkText.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isMyComment && comment.id != null)
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: isDark ? Colors.white38 : AppColors.darkText.withValues(alpha: 0.4),
                    ),
                    onPressed: () => _deleteComment(comment.id!),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              comment.content,
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.darkText,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageViewer(List<String> images, int initialIndex) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            PageView.builder(
              controller: PageController(initialPage: initialIndex),
              itemCount: images.length,
              itemBuilder: (context, index) => InteractiveViewer(
                child: Center(
                  child: Image.network(
                    images[index],
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else if (diff.inDays < 30) {
      return '${(diff.inDays / 7).floor()} weeks ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
