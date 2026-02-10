import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/theme_service.dart';
import '../models/profile.dart';
import '../models/repository.dart';
import '../services/supabase_service.dart';
import 'chat_screen.dart';

/// UserProfileViewScreen - View-only profile screen for other users
/// Mirrors the ProfileScreen design but without edit functionality
class UserProfileViewScreen extends StatefulWidget {
  final String userId;
  final String? userName;
  final String? userAvatar;

  const UserProfileViewScreen({
    super.key,
    required this.userId,
    this.userName,
    this.userAvatar,
  });

  @override
  State<UserProfileViewScreen> createState() => _UserProfileViewScreenState();
}

class _UserProfileViewScreenState extends State<UserProfileViewScreen>
    with SingleTickerProviderStateMixin {
  Profile? _profile;
  List<Repository> _projects = [];
  bool _isLoading = true;
  bool _isConnected = false;
  bool _connectionPending = false;
  late AnimationController _animationController;
  final Set<String> _starredProjects = {};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _loadProfileData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);

    try {
      // Load profile
      final profileData = await SupabaseService.getUserProfile(widget.userId);
      debugPrint('Loaded profile for ${widget.userId}: $profileData');

      // Load user's public projects/repositories
      final projectsData = await SupabaseService.getUserRepositories(widget.userId);
      final allProjects = projectsData.map((p) => Repository.fromJson(p)).toList();
      // Only show public projects to other users
      final projects = allProjects.where((p) => p.isPublic).toList();

      // Check which projects we've starred
      for (final project in projects) {
        if (project.id != null) {
          final starred = await SupabaseService.hasStarredProject(project.id!);
          if (starred) _starredProjects.add(project.id!);
        }
      }

      // Check connection status
      await _checkConnectionStatus();

      if (mounted) {
        setState(() {
          if (profileData != null) {
            _profile = Profile.fromJson(profileData);
          } else {
            // Fallback profile with passed data
            _profile = Profile(
              id: widget.userId,
              fullName: widget.userName ?? 'Unknown User',
              avatarUrl: widget.userAvatar,
            );
          }
          _projects = projects;
          _isLoading = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      if (mounted) {
        setState(() {
          _profile = Profile(
            id: widget.userId,
            fullName: widget.userName ?? 'Unknown User',
            avatarUrl: widget.userAvatar,
          );
          _isLoading = false;
        });
        _animationController.forward();
      }
    }
  }

  Future<void> _checkConnectionStatus() async {
    try {
      // Check if already connected
      final connections = await SupabaseService.getConnections();
      for (final conn in connections) {
        final friend = conn['friend'] as Map<String, dynamic>?;
        if (friend?['id'] == widget.userId) {
          setState(() => _isConnected = true);
          return;
        }
      }

      // Check if there's a pending request
      final pendingRequests = await SupabaseService.getPendingConnectionRequests();
      for (final req in pendingRequests) {
        if (req['receiver_id'] == widget.userId) {
          setState(() => _connectionPending = true);
          return;
        }
      }
    } catch (e) {
      debugPrint('Error checking connection status: $e');
    }
  }

  Future<void> _sendConnectionRequest() async {
    try {
      await SupabaseService.sendConnectionRequest(widget.userId);
      setState(() => _connectionPending = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Connection request sent!'),
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
            content: Text('Failed to send request: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Future<void> _removeConnection() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Connection'),
        content: Text('Are you sure you want to remove ${_profile?.fullName ?? 'this user'} from your connections?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await SupabaseService.removeConnection(widget.userId);
        setState(() => _isConnected = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Connection removed'),
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
              content: Text('Failed to remove connection: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    }
  }

  void _openChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          recipientId: widget.userId,
          recipientName: _profile?.fullName ?? widget.userName ?? 'User',
          recipientAvatar: _profile?.avatarUrl ?? widget.userAvatar,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.grey,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Loading profile...',
                style: TextStyle(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.grey,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Custom App Bar with back button
            SliverAppBar(
              floating: true,
              pinned: false,
              backgroundColor: Colors.transparent,
              leading: Padding(
                padding: const EdgeInsets.all(8),
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_rounded,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),

            // Profile Content
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _animationController,
                child: Column(
                  children: [
                    // Profile Card - Bumble Style
                    _buildProfileCard(isDark),

                    const SizedBox(height: 16),

                    // Stats Section
                    _buildStatsSection(isDark),

                    const SizedBox(height: 16),

                    // About Me Section
                    _buildAboutSection(isDark),

                    const SizedBox(height: 16),

                    // Contact Section
                    _buildContactSection(isDark),

                    const SizedBox(height: 16),

                    // Skills Section
                    _buildSkillsSection(isDark),

                    const SizedBox(height: 16),

                    // Projects Section
                    _buildProjectsSection(isDark),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(bool isDark) {
    final profile = _profile!;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Cover Photo Area
          Container(
            height: 150,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Cover image or gradient fallback
                  if (profile.coverPhotoUrl != null && profile.coverPhotoUrl!.isNotEmpty)
                    Image.network(
                      profile.coverPhotoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildCoverGradient(),
                    )
                  else
                    _buildCoverGradient(),
                  // Gradient overlay on image
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.3),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Profile Info
          Transform.translate(
            offset: const Offset(0, -70),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Profile Picture - Larger Rounded Vertical Rectangle
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.primaryBlue, AppColors.accentPurple],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryBlue.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Container(
                      width: 140,
                      height: 170,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        color: isDark ? AppColors.darkCard : Colors.white,
                        border: Border.all(
                          color: isDark ? AppColors.darkSurface : Colors.white,
                          width: 4,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty
                            ? Image.network(
                                profile.avatarUrl!,
                                fit: BoxFit.cover,
                                width: 140,
                                height: 170,
                                errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(profile),
                              )
                            : _buildAvatarPlaceholder(profile),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Name with Verification Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          profile.fullName,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      if (profile.isVerified) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.primaryBlue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ],
                  ),

                  // Course & Year
                  if (profile.course != null || profile.yearLevel != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        [profile.course, profile.yearLevel]
                            .where((e) => e != null && e.isNotEmpty)
                            .join(' • '),
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                  // Pronouns
                  if (profile.pronouns.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: (isDark ? AppColors.darkCard : AppColors.grey),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        profile.pronouns,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Action Buttons - Message & Connect
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildQuickAction(
                        icon: Icons.message_rounded,
                        label: 'Message',
                        onTap: _openChat,
                        isDark: isDark,
                        isPrimary: true,
                      ),
                      const SizedBox(width: 12),
                      if (_isConnected)
                        _buildQuickAction(
                          icon: Icons.person_remove_rounded,
                          label: 'Connected',
                          onTap: _removeConnection,
                          isDark: isDark,
                          isConnected: true,
                        )
                      else if (_connectionPending)
                        _buildQuickAction(
                          icon: Icons.hourglass_top_rounded,
                          label: 'Pending',
                          onTap: () {},
                          isDark: isDark,
                          isPending: true,
                        )
                      else
                        _buildQuickAction(
                          icon: Icons.person_add_rounded,
                          label: 'Connect',
                          onTap: _sendConnectionRequest,
                          isDark: isDark,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverGradient() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryBlue,
            AppColors.primaryBlue.withOpacity(0.7),
            AppColors.accentPurple.withOpacity(0.5),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarPlaceholder(Profile profile) {
    return Container(
      width: 140,
      height: 170,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryBlue.withOpacity(0.2),
            AppColors.accentPurple.withOpacity(0.2),
          ],
        ),
      ),
      child: Center(
        child: Text(
          profile.fullName.isNotEmpty ? profile.fullName[0].toUpperCase() : '?',
          style: const TextStyle(
            fontSize: 56,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryBlue,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
    bool isPrimary = false,
    bool isConnected = false,
    bool isPending = false,
  }) {
    Color bgColor;
    Color textColor;
    
    if (isPrimary) {
      bgColor = AppColors.primaryBlue;
      textColor = Colors.white;
    } else if (isConnected) {
      bgColor = const Color(0xFF10B981);
      textColor = Colors.white;
    } else if (isPending) {
      bgColor = Colors.orange.withOpacity(0.2);
      textColor = Colors.orange;
    } else {
      bgColor = isDark ? AppColors.darkCard : AppColors.grey;
      textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    }
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: textColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(bool isDark) {
    final profile = _profile!;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStatItem(
            value: '${profile.followersCount}',
            label: 'Connections',
            icon: Icons.people_rounded,
            isDark: isDark,
          ),
          Container(
            height: 40,
            width: 1,
            color: isDark ? AppColors.darkCardBorder : AppColors.cardBorder,
          ),
          _buildStatItem(
            value: '${profile.followingCount}',
            label: 'Following',
            icon: Icons.person_add_rounded,
            isDark: isDark,
          ),
          Container(
            height: 40,
            width: 1,
            color: isDark ? AppColors.darkCardBorder : AppColors.cardBorder,
          ),
          _buildStatItem(
            value: '${_projects.length}',
            label: 'Projects',
            icon: Icons.folder_rounded,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String value,
    required String label,
    required IconData icon,
    required bool isDark,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: AppColors.primaryBlue),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection(bool isDark) {
    final profile = _profile!;
    if (profile.bio.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.person_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                'About Me',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            profile.bio,
            style: TextStyle(
              fontSize: 15,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection(bool isDark) {
    final profile = _profile!;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.contact_mail_rounded,
                  color: AppColors.primaryBlue,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Contact',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Email
          _buildContactRow(
            icon: Icons.email_rounded,
            label: 'Email',
            value: profile.email.isEmpty ? 'Not set' : profile.email,
            color: AppColors.primaryBlue,
            isDark: isDark,
          ),

          // GitHub
          if (profile.githubUsername.isNotEmpty)
            _buildContactRow(
              icon: FontAwesomeIcons.github,
              label: 'GitHub',
              value: '@${profile.githubUsername}',
              color: isDark ? Colors.white : Colors.black,
              isDark: isDark,
            ),

          // LinkedIn
          if (profile.linkedinUsername.isNotEmpty)
            _buildContactRow(
              icon: FontAwesomeIcons.linkedin,
              label: 'LinkedIn',
              value: profile.linkedinUsername,
              color: const Color(0xFF0A66C2),
              isDark: isDark,
            ),

          // Facebook
          if (profile.facebookUsername.isNotEmpty)
            _buildContactRow(
              icon: FontAwesomeIcons.facebook,
              label: 'Facebook',
              value: profile.facebookUsername,
              color: const Color(0xFF1877F2),
              isDark: isDark,
            ),
        ],
      ),
    );
  }

  Widget _buildContactRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsSection(bool isDark) {
    final profile = _profile!;
    final hasSkills = profile.skills.isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.lightbulb_rounded,
                  color: Color(0xFFF59E0B),
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Skills',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Skills display
          if (!hasSkills)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.grey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'No skills listed',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: profile.skills.map((skill) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryBlue.withOpacity(0.15),
                        AppColors.primaryBlue.withOpacity(0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primaryBlue.withOpacity(0.25),
                    ),
                  ),
                  child: Text(
                    skill,
                    style: TextStyle(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.primaryBlue,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildProjectsSection(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accentPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.folder_special_rounded,
                  color: AppColors.accentPurple,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Projects',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Projects List or Empty State
          if (_projects.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.grey,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.folder_open_rounded,
                    size: 48,
                    color: isDark
                        ? AppColors.darkTextSecondary.withOpacity(0.5)
                        : AppColors.textSecondary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No projects yet',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: _projects.map((project) {
                return _buildProjectCard(project, isDark);
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildProjectCard(Repository project, bool isDark) {
    final hasThumbnail = project.thumbnailUrl != null && project.thumbnailUrl!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.grey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : AppColors.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail Image or Placeholder
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: Stack(
              children: [
                if (hasThumbnail)
                  Image.network(
                    project.thumbnailUrl!,
                    width: double.infinity,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildProjectPlaceholder(project, isDark),
                  )
                else
                  _buildProjectPlaceholder(project, isDark),
                // Gradient overlay
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.4),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Project Info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
                if (project.description != null && project.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    project.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                  ),
                ],
                if (project.technologies.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: project.technologies.take(3).map((tech) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          tech,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                // Star button section
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildStarButton(project, isDark),
                    const SizedBox(width: 8),
                    Text(
                      '${project.stars} ${project.stars == 1 ? 'star' : 'stars'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarButton(Repository project, bool isDark) {
    final isStarred = _starredProjects.contains(project.id);
    
    return InkWell(
      onTap: () => _toggleStar(project),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isStarred 
              ? const Color(0xFFFEF3C7)
              : (isDark ? AppColors.darkCard : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isStarred 
                ? const Color(0xFFF59E0B)
                : (isDark ? AppColors.darkCardBorder : AppColors.cardBorder),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isStarred ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 16,
              color: isStarred ? const Color(0xFFF59E0B) : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
            ),
            const SizedBox(width: 4),
            Text(
              isStarred ? 'Starred' : 'Star',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isStarred ? const Color(0xFFF59E0B) : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleStar(Repository project) async {
    if (project.id == null) return;
    
    final isStarred = _starredProjects.contains(project.id);
    
    // Optimistic update
    setState(() {
      if (isStarred) {
        _starredProjects.remove(project.id);
      } else {
        _starredProjects.add(project.id!);
      }
    });
    
    try {
      if (isStarred) {
        await SupabaseService.unstarProject(project.id!);
      } else {
        await SupabaseService.starProject(project.id!);
      }
      
      // Reload projects to get updated star count
      final projectsData = await SupabaseService.getUserRepositories(widget.userId);
      final allProjects = projectsData.map((p) => Repository.fromJson(p)).toList();
      if (mounted) {
        setState(() {
          _projects = allProjects.where((p) => p.isPublic).toList();
        });
      }
    } catch (e) {
      // Revert on error
      setState(() {
        if (isStarred) {
          _starredProjects.add(project.id!);
        } else {
          _starredProjects.remove(project.id);
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to ${isStarred ? 'unstar' : 'star'} project'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Widget _buildProjectPlaceholder(Repository project, bool isDark) {
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accentPurple.withOpacity(0.3),
            AppColors.primaryBlue.withOpacity(0.3),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.code_rounded,
          size: 40,
          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
        ),
      ),
    );
  }
}
