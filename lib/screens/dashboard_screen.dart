import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/theme_service.dart';
import '../services/connectivity_service.dart';
import '../models/profile.dart';
import '../models/activity.dart';
import '../services/supabase_service.dart';
import '../widgets/activity_tile.dart';
import 'profile_screen.dart';

/// Dashboard Screen
/// Main home dashboard displaying user stats and recent activity.
/// Matches the Bumble-inspired UI design with hamburger menu, greeting, quick actions, 
/// overview grid, and recent activity. Supports real-time data updates.
class DashboardScreen extends StatefulWidget {
  final Profile profile;
  final Function(Profile) onProfileUpdate;
  final VoidCallback onNavigateToFriends;
  final VoidCallback onNavigateToRepositories;
  final GlobalKey<ScaffoldState>? scaffoldKey;

  const DashboardScreen({
    super.key,
    required this.profile,
    required this.onProfileUpdate,
    required this.onNavigateToFriends,
    required this.onNavigateToRepositories,
    this.scaffoldKey,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Activity> _activities = [];
  bool _isLoading = true;
  int _projectsCount = 0;
  int _friendsCount = 0;
  int _skillsCount = 0;
  int _profileViews = 0;
  
  // Real-time subscriptions
  RealtimeChannel? _activitiesSubscription;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _setupRealtimeSubscriptions();
  }

  @override
  void dispose() {
    _activitiesSubscription?.unsubscribe();
    super.dispose();
  }

  void _setupRealtimeSubscriptions() {
    final userId = SupabaseService.userId;
    if (userId == null) return;

    // Subscribe to activities changes
    _activitiesSubscription = SupabaseService.client
        .channel('dashboard_activities:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'activities',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            // Reload activities when they change
            _loadDashboardData();
          },
        )
        .subscribe();
  }

  Future<void> _loadDashboardData() async {
    try {
      // Load real data from Supabase in parallel
      final results = await Future.wait([
        SupabaseService.getMyActivities(),
        SupabaseService.getMyProjects(),
        SupabaseService.getConnections(),
        SupabaseService.getProfile(),
      ]);

      final activitiesData = results[0] as List<Map<String, dynamic>>;
      final projectsData = results[1] as List<Map<String, dynamic>>;
      final connectionsData = results[2] as List<Map<String, dynamic>>;
      final profileData = results[3] as Map<String, dynamic>?;

      if (mounted) {
        setState(() {
          _activities = activitiesData.map((data) => Activity.fromJson(data)).toList();
          _projectsCount = projectsData.length;
          _friendsCount = connectionsData.length;
          _skillsCount = (profileData?['skills'] as List?)?.length ?? 0;
          _profileViews = profileData?['profile_views'] ?? 0;
          _isLoading = false;
        });

        // Update profile if data available
        if (profileData != null) {
          widget.onProfileUpdate(Profile.fromJson(profileData));
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      debugPrint('Error loading dashboard data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDashboardData,
          color: AppColors.primaryBlue,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  
                  // Offline indicator
                  Consumer<ConnectivityService>(
                    builder: (context, connectivity, _) {
                      if (connectivity.isConnected) return const SizedBox.shrink();
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.wifi_off_rounded, size: 18, color: Colors.red.shade700),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'No internet connection. Some features may be unavailable.',
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  
                  // Header with hamburger menu and greeting
                  _buildHeader(isDark),

                  const SizedBox(height: 28),

                  // Quick Actions
                  _buildQuickActions(isDark),

                  const SizedBox(height: 28),

                  // Overview Section
                  _buildOverviewSection(isDark),

                  const SizedBox(height: 28),

                  // Recent Activity Section
                  _buildRecentActivitySection(isDark),

                  const SizedBox(height: 100), // Bottom padding for nav bar
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Row(
      children: [
        // Hamburger menu button
        GestureDetector(
          onTap: () {
            widget.scaffoldKey?.currentState?.openDrawer();
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.white12 : AppColors.cardBorder,
              ),
            ),
            child: Icon(
              Icons.menu_rounded,
              color: AppColors.primaryBlue,
              size: 22,
            ),
          ),
        ),
        const SizedBox(width: 16),

        // Greeting text
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white60 : AppColors.darkText.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.profile.fullName.isNotEmpty 
                    ? widget.profile.fullName.split(' ').first
                    : 'Student',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.darkText,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),

        // Profile avatar
        GestureDetector(
          onTap: () => _navigateToProfile(),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryBlue.withValues(alpha: 0.2),
              border: Border.all(color: AppColors.primaryBlue, width: 2),
            ),
            child: widget.profile.avatarUrl != null
                ? ClipOval(
                    child: Image.network(
                      widget.profile.avatarUrl!,
                      fit: BoxFit.cover,
                    ),
                  )
                : Center(
                    child: Text(
                      widget.profile.fullName.isNotEmpty
                          ? widget.profile.fullName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.primaryBlue : AppColors.darkText,
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppColors.darkText,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _buildActionButton(
              icon: Icons.person_add_rounded,
              label: 'Add\nConnection',
              isDark: isDark,
              onTap: widget.onNavigateToFriends,
            ),
            const SizedBox(width: 12),
            _buildActionButton(
              icon: Icons.add_box_rounded,
              label: 'New\nProject',
              isDark: isDark,
              onTap: widget.onNavigateToRepositories,
            ),
            const SizedBox(width: 12),
            _buildActionButton(
              icon: Icons.share_rounded,
              label: 'Share\nProfile',
              isDark: isDark,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Profile link copied!'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    backgroundColor: AppColors.primaryBlue,
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white12 : AppColors.cardBorder,
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primaryBlue, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : AppColors.darkText.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppColors.darkText,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 14),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: [
            _buildOverviewCard(
              title: 'Projects',
              value: '$_projectsCount',
              icon: Icons.folder_rounded,
              iconBgColor: AppColors.primaryBlue.withValues(alpha: 0.2),
              iconColor: AppColors.primaryBlue,
              isDark: isDark,
              onTap: widget.onNavigateToRepositories,
            ),
            _buildOverviewCard(
              title: 'Connections',
              value: '$_friendsCount',
              icon: Icons.people_rounded,
              iconBgColor: const Color(0xFFDBEAFE),
              iconColor: const Color(0xFF3B82F6),
              isDark: isDark,
              onTap: widget.onNavigateToFriends,
            ),
            _buildOverviewCard(
              title: 'Skills',
              value: '$_skillsCount',
              icon: Icons.lightbulb_rounded,
              iconBgColor: const Color(0xFFD1FAE5),
              iconColor: const Color(0xFF10B981),
              isDark: isDark,
              onTap: () => _navigateToProfile(),
            ),
            _buildOverviewCard(
              title: 'Profile Views',
              value: '$_profileViews',
              icon: Icons.visibility_rounded,
              iconBgColor: const Color(0xFFE9D5FF),
              iconColor: const Color(0xFF8B5CF6),
              isDark: isDark,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOverviewCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white12 : AppColors.cardBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? iconBgColor.withValues(alpha: 0.3) : iconBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                if (onTap != null)
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: isDark ? Colors.white30 : AppColors.darkText.withValues(alpha: 0.3),
                    size: 14,
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.darkText,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white60 : AppColors.darkText.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.darkText,
                letterSpacing: -0.3,
              ),
            ),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'See All',
                style: TextStyle(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (_activities.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white12 : AppColors.cardBorder,
              ),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 40,
                    color: isDark ? Colors.white30 : AppColors.darkText.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No recent activity',
                    style: TextStyle(
                      color: isDark ? Colors.white60 : AppColors.darkText.withValues(alpha: 0.6),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white12 : AppColors.cardBorder,
              ),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _activities.length > 3 ? 3 : _activities.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: isDark ? Colors.white12 : Colors.grey.shade200,
              ),
              itemBuilder: (context, index) {
                return ActivityTile(activity: _activities[index]);
              },
            ),
          ),
      ],
    );
  }

  void _navigateToProfile() async {
    final updatedProfile = await Navigator.push<Profile>(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(
          profile: widget.profile,
          onProfileUpdate: widget.onProfileUpdate,
        ),
      ),
    );

    if (updatedProfile != null) {
      widget.onProfileUpdate(updatedProfile);
    }
  }
}
