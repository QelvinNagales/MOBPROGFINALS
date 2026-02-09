import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/theme_service.dart';
import '../models/profile.dart';
import '../models/repository.dart';
import '../services/supabase_service.dart';
import '../widgets/skill_selection_sheet.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';
import 'add_project_screen.dart';

/// Profile Screen - Bumble-Inspired Design
/// Displays the student's full profile for networking and group matching.
/// Features: Back button, skill selection, project management, real-time updates
class ProfileScreen extends StatefulWidget {
  final Profile? profile;
  final Function(Profile)? onProfileUpdate;
  final bool showBackButton;

  const ProfileScreen({
    super.key,
    this.profile,
    this.onProfileUpdate,
    this.showBackButton = true,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late Profile _profile;
  List<Repository> _projects = [];
  bool _isLoading = true;
  late AnimationController _animationController;
  RealtimeChannel? _profileSubscription;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _loadProfile();
    _setupRealtimeSubscription();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _unsubscribeFromRealtime();
    super.dispose();
  }

  void _setupRealtimeSubscription() {
    if (SupabaseService.userId == null) return;
    
    _profileSubscription = SupabaseService.client
        .channel('profile:${SupabaseService.userId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'profiles',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: SupabaseService.userId,
          ),
          callback: (payload) {
            if (mounted) {
              setState(() {
                _profile = Profile.fromJson(payload.newRecord);
              });
              widget.onProfileUpdate?.call(_profile);
            }
          },
        )
        .subscribe();
  }

  void _unsubscribeFromRealtime() {
    if (_profileSubscription != null) {
      SupabaseService.unsubscribe(_profileSubscription!);
    }
  }

  Future<void> _loadProfile() async {
    if (widget.profile != null) {
      setState(() {
        _profile = widget.profile!;
        _isLoading = false;
      });
      _animationController.forward();
      _loadProjects();
      return;
    }

    try {
      final profileData = await SupabaseService.getProfile();
      if (profileData != null && mounted) {
        setState(() {
          _profile = Profile.fromJson(profileData);
          _isLoading = false;
        });
        _animationController.forward();
        _loadProjects();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _profile = Profile();
          _isLoading = false;
        });
        _animationController.forward();
      }
    }
  }

  Future<void> _loadProjects() async {
    try {
      final projects = await SupabaseService.getMyProjects();
      if (mounted) {
        setState(() {
          _projects = projects.map((p) => Repository.fromJson(p)).toList();
        });
      }
    } catch (e) {
      // Ignore errors loading projects
    }
  }

  void _navigateToEditProfile() async {
    final updatedProfile = await Navigator.push<Profile>(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(profile: _profile),
      ),
    );

    if (updatedProfile != null) {
      setState(() {
        _profile = updatedProfile;
      });
      widget.onProfileUpdate?.call(updatedProfile);
    }
  }

  void _showSkillSelection() {
    showSkillSelectionSheet(
      context,
      selectedSkills: _profile.skills,
      onSkillsChanged: (skills) async {
        setState(() {
          _profile.skills = skills;
        });
        
        // Save to database
        try {
          await SupabaseService.updateProfile({'skills': skills});
          widget.onProfileUpdate?.call(_profile);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error saving skills: $e'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      },
    );
  }

  void _navigateToAddProject() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const AddProjectScreen(),
      ),
    );

    if (result == true) {
      _loadProjects();
    }
  }

  void _editProject(Repository project) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddProjectScreen(existingProject: project),
      ),
    );

    if (result == true) {
      _loadProjects();
    }
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
              leading: widget.showBackButton
                  ? Padding(
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
                    )
                  : null,
              actions: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    },
                    child: Container(
                      width: 40,
                      height: 40,
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
                        Icons.settings_rounded,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
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

                    // Skills Section (Interactive)
                    _buildSkillsSection(isDark),

                    const SizedBox(height: 16),

                    // Contact Section
                    _buildContactSection(isDark),

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
          // Cover Photo Area with Gradient
          Container(
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryBlue,
                  AppColors.primaryBlue.withOpacity(0.7),
                  AppColors.primaryBlue.withOpacity(0.3),
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
            ),
            child: Stack(
              children: [
                // Pattern overlay
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.1,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                      child: Image.network(
                        'https://www.transparenttextures.com/patterns/cubes.png',
                        repeat: ImageRepeat.repeat,
                      ),
                    ),
                  ),
                ),
                // Edit button
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: _navigateToEditProfile,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        size: 18,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Profile Info
          Transform.translate(
            offset: const Offset(0, -50),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Profile Picture with Ring
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryBlue,
                    ),
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? AppColors.darkCard : Colors.white,
                        border: Border.all(
                          color: isDark ? AppColors.darkSurface : Colors.white,
                          width: 4,
                        ),
                      ),
                      child: _profile.avatarUrl != null
                          ? ClipOval(
                              child: Image.network(
                                _profile.avatarUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(),
                              ),
                            )
                          : _buildAvatarPlaceholder(),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Name with Verification Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          _profile.fullName,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      if (_profile.isVerified) ...[
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
                            color: Color.fromARGB(255, 255, 255, 255),
                          ),
                        ),
                      ],
                    ],
                  ),

                  // Course & Year
                  if (_profile.course != null || _profile.yearLevel != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        [_profile.course, _profile.yearLevel]
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
                  if (_profile.pronouns.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: (isDark ? AppColors.darkCard : AppColors.grey),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _profile.pronouns,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Quick Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildQuickAction(
                        icon: Icons.share_rounded,
                        label: 'Share',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Profile link copied!')),
                          );
                        },
                        isDark: isDark,
                      ),
                      const SizedBox(width: 12),
                      _buildQuickAction(
                        icon: Icons.qr_code_rounded,
                        label: 'QR Code',
                        onTap: () {},
                        isDark: isDark,
                      ),
                      const SizedBox(width: 12),
                      _buildQuickAction(
                        icon: Icons.edit_rounded,
                        label: 'Edit',
                        onTap: _navigateToEditProfile,
                        isDark: isDark,
                        isPrimary: true,
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

  Widget _buildAvatarPlaceholder() {
    return Center(
      child: Text(
        _profile.fullName.isNotEmpty ? _profile.fullName[0].toUpperCase() : '?',
        style: const TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.w800,
          color: AppColors.primaryBlue,
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
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isPrimary
              ? AppColors.primaryBlue
              : (isDark ? AppColors.darkCard : AppColors.grey),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isPrimary
                  ? Colors.black
                  : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isPrimary
                    ? Colors.black
                    : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(bool isDark) {
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
            value: '${_profile.followersCount}',
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
            value: '${_profile.followingCount}',
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
    if (_profile.bio.isEmpty) return const SizedBox.shrink();

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
            _profile.bio,
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

  Widget _buildSkillsSection(bool isDark) {
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
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.lightbulb_rounded,
                  color: Color(0xFFF59E0B),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Skills',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _showSkillSelection,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.edit_rounded,
                        size: 14,
                        color: AppColors.primaryBlue,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Edit',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Skills or Add Button
          if (_profile.skills.isEmpty)
            GestureDetector(
              onTap: _showSkillSelection,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.grey,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primaryBlue.withOpacity(0.3),
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.add_circle_outline_rounded,
                      size: 32,
                      color: AppColors.primaryBlue,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add your skills',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Help others understand your expertise',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _profile.skills.map((skill) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryBlue.withOpacity(0.2),
                        AppColors.primaryBlue.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primaryBlue.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    skill,
                    style: TextStyle(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.primaryBlue,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildContactSection(bool isDark) {
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
            value: _profile.email.isEmpty ? 'Not set' : _profile.email,
            color: AppColors.primaryBlue,
            isDark: isDark,
          ),

          // GitHub
          if (_profile.githubUsername.isNotEmpty)
            _buildContactRow(
              icon: FontAwesomeIcons.github,
              label: 'GitHub',
              value: '@${_profile.githubUsername}',
              color: isDark ? Colors.white : Colors.black,
              isDark: isDark,
            ),

          // LinkedIn
          if (_profile.linkedinUsername.isNotEmpty)
            _buildContactRow(
              icon: FontAwesomeIcons.linkedin,
              label: 'LinkedIn',
              value: _profile.linkedinUsername,
              color: const Color(0xFF0A66C2),
              isDark: isDark,
            ),

          // Facebook
          if (_profile.facebookUsername.isNotEmpty)
            _buildContactRow(
              icon: FontAwesomeIcons.facebook,
              label: 'Facebook',
              value: _profile.facebookUsername,
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
              GestureDetector(
                onTap: _navigateToAddProject,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                      const SizedBox(width: 4),
                      const Text(
                        'Add',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Projects List or Empty State
          if (_projects.isEmpty)
            GestureDetector(
              onTap: _navigateToAddProject,
              child: Container(
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
                    const SizedBox(height: 4),
                    Text(
                      'Showcase your work to potential groupmates',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Create your first project',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
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
    return GestureDetector(
      onTap: () => _editProject(project),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
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
            Row(
              children: [
                // Project Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getLanguageColor(project.language).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.folder_rounded,
                    color: _getLanguageColor(project.language),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        project.language,
                        style: TextStyle(
                          fontSize: 12,
                          color: _getLanguageColor(project.language),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(project.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusLabel(project.status),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _getStatusColor(project.status),
                    ),
                  ),
                ),
              ],
            ),
            if (project.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                project.description,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            // Stats Row
            Row(
              children: [
                _buildProjectStat(
                  Icons.star_rounded,
                  '${project.starsCount}',
                  AppColors.primaryBlue,
                  isDark,
                ),
                const SizedBox(width: 16),
                if (project.githubUrl != null && project.githubUrl!.isNotEmpty)
                  _buildProjectStat(
                    FontAwesomeIcons.github,
                    'GitHub',
                    isDark ? Colors.white : Colors.black,
                    isDark,
                  ),
              ],
            ),
            // Technologies
            if (project.technologies.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: project.technologies.take(4).map((tech) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkBackground : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tech,
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProjectStat(IconData icon, String value, Color color, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Color _getLanguageColor(String language) {
    final colors = {
      'Dart': const Color(0xFF0175C2),
      'Python': const Color(0xFF3776AB),
      'JavaScript': const Color(0xFFF7DF1E),
      'TypeScript': const Color(0xFF3178C6),
      'Java': const Color(0xFF007396),
      'Kotlin': const Color(0xFF7F52FF),
      'Swift': const Color(0xFFFA7343),
      'C++': const Color(0xFF00599C),
      'C#': const Color(0xFF512BD4),
    };
    return colors[language] ?? AppColors.primaryBlue;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return AppColors.success;
      case 'in_progress':
        return AppColors.warning;
      case 'idea':
        return AppColors.primaryBlue;
      case 'archived':
        return AppColors.darkGrey;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'completed':
        return 'Completed';
      case 'in_progress':
        return 'In Progress';
      case 'idea':
        return 'Idea';
      case 'archived':
        return 'Archived';
      default:
        return status;
    }
  }
}
