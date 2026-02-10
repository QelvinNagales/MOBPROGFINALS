import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart' show themeService;
import '../services/theme_service.dart';
import '../services/supabase_service.dart';
import '../models/profile.dart';
import 'repositories_screen.dart';
import 'explore_screen.dart';
import 'friends_screen.dart';
import 'notifications_screen.dart';
import 'settings_screen.dart';
import 'profile_screen.dart';
import 'messages_screen.dart';

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
  
  // Unread message count
  int _messageCount = 0;
  
  // Real-time subscriptions
  RealtimeChannel? _profileSubscription;
  RealtimeChannel? _notificationSubscription;
  RealtimeChannel? _messageSubscription;
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
    _messageSubscription?.unsubscribe();
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
      
      // Load unread message count
      await _loadMessageCount();
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

  Future<void> _loadMessageCount() async {
    try {
      final count = await SupabaseService.getUnreadMessageCount();
      if (mounted) {
        setState(() {
          _messageCount = count;
        });
      }
    } catch (e) {
      debugPrint('Error loading message count: $e');
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

    // Subscribe to message changes
    _messageSubscription = SupabaseService.client
        .channel('home_messages:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'messages',
          callback: (payload) {
            // Reload message count when messages change
            _loadMessageCount();
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
          // Feed (Explore) - Now the home screen
          ExploreScreen(scaffoldKey: _scaffoldKey),
          // Projects (Repositories)
          RepositoriesScreen(scaffoldKey: _scaffoldKey),
          // Messages - Replaces old Dashboard
          MessagesScreen(scaffoldKey: _scaffoldKey),
          // Network (Friends)
          FriendsScreen(scaffoldKey: _scaffoldKey),
          // Notifications
          NotificationsScreen(scaffoldKey: _scaffoldKey),
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
              icon: Icon(Icons.dynamic_feed_outlined, color: isDark ? Colors.white70 : null),
              selectedIcon: const Icon(Icons.dynamic_feed_rounded, color: AppColors.primaryBlue),
              label: 'Feed',
            ),
            NavigationDestination(
              icon: Icon(Icons.folder_outlined, color: isDark ? Colors.white70 : null),
              selectedIcon: const Icon(Icons.folder_rounded, color: AppColors.primaryBlue),
              label: 'Projects',
            ),
            NavigationDestination(
              icon: Badge(
                label: _messageCount > 0
                    ? Text('$_messageCount', style: const TextStyle(fontSize: 10, color: Colors.black))
                    : null,
                isLabelVisible: _messageCount > 0,
                backgroundColor: AppColors.primaryBlue,
                child: Icon(Icons.chat_bubble_outline_rounded, color: isDark ? Colors.white70 : null),
              ),
              selectedIcon: Badge(
                label: _messageCount > 0
                    ? Text('$_messageCount', style: const TextStyle(fontSize: 10, color: Colors.black))
                    : null,
                isLabelVisible: _messageCount > 0,
                backgroundColor: AppColors.primaryBlue,
                child: const Icon(Icons.chat_bubble_rounded, color: AppColors.primaryBlue),
              ),
              label: 'Messages',
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
                        _createSmoothPageRoute(
                          ProfileScreen(
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
                    icon: Icons.chat_bubble_rounded,
                    title: 'Messages',
                    selected: _currentIndex == 2,
                    badge: _messageCount > 0 ? _messageCount : null,
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

                  // Dark/Light Mode Toggle
                  _buildThemeToggle(isDark),

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
                        _createSmoothPageRoute(const SettingsScreen()),
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

  Widget _buildThemeToggle(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isDark 
              ? AppColors.primaryBlue.withValues(alpha: 0.15)
              : AppColors.primaryBlue.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          leading: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return RotationTransition(
                turns: animation,
                child: ScaleTransition(scale: animation, child: child),
              );
            },
            child: Icon(
              isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              key: ValueKey<bool>(isDark),
              color: AppColors.primaryBlue,
              size: 22,
            ),
          ),
          title: Text(
            isDark ? 'Dark Mode' : 'Light Mode',
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.darkText,
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
          ),
          trailing: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: 50,
            height: 28,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: isDark 
                  ? AppColors.primaryBlue 
                  : AppColors.darkGrey.withValues(alpha: 0.3),
            ),
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  left: isDark ? 24 : 2,
                  top: 2,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        isDark ? Icons.nights_stay_rounded : Icons.wb_sunny_rounded,
                        size: 14,
                        color: isDark ? AppColors.primaryBlue : AppColors.warning,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onTap: () {
            themeService.toggleDarkMode();
          },
        ),
      ),
    );
  }

  Route _createSmoothPageRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 350),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        var fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: FadeTransition(
            opacity: fadeAnimation,
            child: child,
          ),
        );
      },
    );
  }
}
