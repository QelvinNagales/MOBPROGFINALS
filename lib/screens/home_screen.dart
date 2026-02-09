import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/theme_service.dart';
import '../services/supabase_service.dart';
import '../models/profile.dart';
import 'dashboard_screen.dart';
import 'repositories_screen.dart';
import 'explore_screen.dart';
import 'friends_screen.dart';
import 'notifications_screen.dart';
import 'settings_screen.dart';
import 'profile_screen.dart';

/// Home Screen
/// Main container with bottom navigation bar for navigating between sections.
/// Features real-time data subscriptions for profile and notifications.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;
  
  // In-memory profile data
  Profile _profile = Profile();

  // Notification count for badge - now real-time
  int _notificationCount = 0;
  
  // Real-time subscriptions
  RealtimeChannel? _profileSubscription;
  RealtimeChannel? _notificationSubscription;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _setupRealtimeSubscriptions();
  }

  @override
  void dispose() {
    _profileSubscription?.unsubscribe();
    _notificationSubscription?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      // Load profile
      final profileData = await SupabaseService.getProfile();
      if (profileData != null && mounted) {
        setState(() {
          _profile = Profile.fromJson(profileData);
        });
      }
      
      // Load unread notification count
      await _loadNotificationCount();
    } catch (e) {
      debugPrint('Error loading initial data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadNotificationCount() async {
    try {
      final userId = SupabaseService.userId;
      if (userId == null) return;
      
      final response = await SupabaseService.client
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('is_read', false);
      
      if (mounted) {
        setState(() {
          _notificationCount = (response as List).length;
        });
      }
    } catch (e) {
      debugPrint('Error loading notification count: $e');
    }
  }

  void _setupRealtimeSubscriptions() {
    final userId = SupabaseService.userId;
    if (userId == null) return;

    // Subscribe to profile changes
    _profileSubscription = SupabaseService.client
        .channel('home_profile:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'profiles',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: userId,
          ),
          callback: (payload) {
            if (payload.newRecord.isNotEmpty && mounted) {
              setState(() {
                _profile = Profile.fromJson(payload.newRecord);
              });
            }
          },
        )
        .subscribe();

    // Subscribe to notification changes
    _notificationSubscription = SupabaseService.client
        .channel('home_notifications:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            // Reload notification count when notifications change
            _loadNotificationCount();
          },
        )
        .subscribe();
  }

  void _onProfileUpdate(Profile updatedProfile) {
    setState(() {
      _profile = updatedProfile;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      key: _scaffoldKey,
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryBlue,
              ),
            )
          : IndexedStack(
        index: _currentIndex,
        children: [
          // Dashboard
          DashboardScreen(
            profile: _profile,
            onProfileUpdate: _onProfileUpdate,
            onNavigateToFriends: () => setState(() => _currentIndex = 3),
            onNavigateToRepositories: () => setState(() => _currentIndex = 1),
            scaffoldKey: _scaffoldKey,
          ),
          // Repositories
          const RepositoriesScreen(),
          // Explore
          const ExploreScreen(),
          // Network (Friends)
          const FriendsScreen(),
          // Notifications
          const NotificationsScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          indicatorColor: AppColors.primaryBlue.withValues(alpha: 0.3),
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.home_outlined, color: isDark ? Colors.white70 : null),
              selectedIcon: const Icon(Icons.home_rounded, color: AppColors.primaryBlue),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.folder_outlined, color: isDark ? Colors.white70 : null),
              selectedIcon: const Icon(Icons.folder_rounded, color: AppColors.primaryBlue),
              label: 'Projects',
            ),
            NavigationDestination(
              icon: Icon(Icons.explore_outlined, color: isDark ? Colors.white70 : null),
              selectedIcon: const Icon(Icons.explore_rounded, color: AppColors.primaryBlue),
              label: 'Explore',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline_rounded, color: isDark ? Colors.white70 : null),
              selectedIcon: const Icon(Icons.people_rounded, color: AppColors.primaryBlue),
              label: 'Network',
            ),
            NavigationDestination(
              icon: Badge(
                label: _notificationCount > 0
                    ? Text('$_notificationCount', style: const TextStyle(fontSize: 10, color: Colors.black))
                    : null,
                isLabelVisible: _notificationCount > 0,
                backgroundColor: AppColors.primaryBlue,
                child: Icon(Icons.notifications_outlined, color: isDark ? Colors.white70 : null),
              ),
              selectedIcon: Badge(
                label: _notificationCount > 0
                    ? Text('$_notificationCount', style: const TextStyle(fontSize: 10, color: Colors.black))
                    : null,
                isLabelVisible: _notificationCount > 0,
                backgroundColor: AppColors.primaryBlue,
                child: const Icon(Icons.notifications_rounded, color: AppColors.primaryBlue),
              ),
              label: 'Alerts',
            ),
          ],
        ),
      ),
      drawer: _buildDrawer(isDark),
    );
  }

  Widget _buildDrawer(bool isDark) {
    return Drawer(
      backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Modern Drawer Header with Bumble-inspired gradient
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryBlue.withValues(alpha: isDark ? 0.2 : 0.1),
                    isDark ? AppColors.darkBackground : Colors.white,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryBlue.withValues(alpha: 0.2),
                      border: Border.all(
                        color: AppColors.primaryBlue,
                        width: 3,
                      ),
                    ),
                    child: _profile.avatarUrl != null
                        ? ClipOval(
                            child: Image.network(
                              _profile.avatarUrl!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Center(
                            child: Text(
                              _profile.fullName.isNotEmpty
                                  ? _profile.fullName[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.primaryBlue : AppColors.darkText,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _profile.fullName.isEmpty ? 'APC Student' : _profile.fullName,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      color: isDark ? Colors.white : AppColors.darkText,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _profile.email.isEmpty ? 'student@apc.edu.ph' : _profile.email,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : AppColors.darkText.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: isDark ? Colors.white12 : Colors.grey.shade200),

            // Navigation Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildDrawerItem(
                    icon: Icons.home_rounded,
                    title: 'Home',
                    selected: _currentIndex == 0,
                    isDark: isDark,
                    onTap: () {
                      setState(() => _currentIndex = 0);
                      Navigator.pop(context);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.person_rounded,
                    title: 'My Profile',
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileScreen(
                            profile: _profile,
                            onProfileUpdate: _onProfileUpdate,
                          ),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.folder_rounded,
                    title: 'My Projects',
                    selected: _currentIndex == 1,
                    isDark: isDark,
                    onTap: () {
                      setState(() => _currentIndex = 1);
                      Navigator.pop(context);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.explore_rounded,
                    title: 'Explore',
                    selected: _currentIndex == 2,
                    isDark: isDark,
                    onTap: () {
                      setState(() => _currentIndex = 2);
                      Navigator.pop(context);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.people_rounded,
                    title: 'My Network',
                    selected: _currentIndex == 3,
                    isDark: isDark,
                    onTap: () {
                      setState(() => _currentIndex = 3);
                      Navigator.pop(context);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.notifications_rounded,
                    title: 'Notifications',
                    selected: _currentIndex == 4,
                    badge: _notificationCount > 0 ? _notificationCount : null,
                    isDark: isDark,
                    onTap: () {
                      setState(() => _currentIndex = 4);
                      Navigator.pop(context);
                    },
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Divider(height: 1, color: isDark ? Colors.white12 : Colors.grey.shade200),
                  ),

                  _buildDrawerItem(
                    icon: Icons.bookmark_rounded,
                    title: 'Saved Items',
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Coming soon!'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          backgroundColor: AppColors.primaryBlue,
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.analytics_rounded,
                    title: 'Analytics',
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Coming soon!'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          backgroundColor: AppColors.primaryBlue,
                        ),
                      );
                    },
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Divider(height: 1, color: isDark ? Colors.white12 : Colors.grey.shade200),
                  ),

                  _buildDrawerItem(
                    icon: Icons.settings_rounded,
                    title: 'Settings',
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.help_outline_rounded,
                    title: 'Help & Feedback',
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Opening help center...'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          backgroundColor: AppColors.primaryBlue,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // App Version
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'APC Student Network v1.0.0',
                style: TextStyle(
                  color: isDark ? Colors.white38 : AppColors.darkText.withValues(alpha: 0.4),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    bool selected = false,
    int? badge,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        leading: Icon(
          icon,
          color: selected ? AppColors.primaryBlue : (isDark ? Colors.white70 : AppColors.darkText.withValues(alpha: 0.6)),
          size: 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: selected ? AppColors.primaryBlue : (isDark ? Colors.white : AppColors.darkText),
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 15,
          ),
        ),
        trailing: badge != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$badge',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              )
            : null,
        selected: selected,
        selectedTileColor: AppColors.primaryBlue.withValues(alpha: 0.15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: onTap,
      ),
    );
  }
}
