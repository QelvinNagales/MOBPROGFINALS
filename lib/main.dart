import 'package:flutter/material.dart';
import 'services/supabase_service.dart';
import 'services/theme_service.dart';
import 'screens/splash_screen.dart';

/// APC Student Networking App - Bumble-Style Student Matching Platform
/// Main entry point of the Flutter application.
/// 
/// This app is a student networking platform for Asia Pacific College (APC)
/// where students can create profiles, showcase projects, manage connections,
/// and discover compatible groupmates for networking - inspired by Bumble.
///
/// Architecture:
/// - models/     → Data models (Profile, Friend, Repository, Activity, Notification)
/// - screens/    → Full-page screens (Home, Dashboard, Profile, Repositories, Explore, etc.)
/// - widgets/    → Reusable UI components (ProfileCard, FriendTile, StatCard, etc.)
/// - services/   → Supabase service for real-time database operations
///
/// Features:
/// - Real-time database with Supabase
/// - Dark mode support
/// - Bumble-inspired UI/UX
/// - Skill-based matching
/// - Project portfolios with GitHub integration
///
/// Navigation: Bottom NavigationBar with Drawer for additional options
/// State Management: Supabase real-time database + ChangeNotifier for theme

// Global theme notifier for app-wide theme changes
final themeService = ThemeService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await SupabaseService.initialize();
  
  runApp(const MyApp());
}

/// Root widget of the application
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    themeService.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    themeService.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'APC Student Network',
      debugShowCheckedModeBanner: false,

      // Light theme - Bumble inspired
      theme: lightTheme,
      
      // Dark theme
      darkTheme: darkTheme,
      
      // Theme mode from service
      themeMode: themeService.themeMode,

      // Start with splash screen
      home: const SplashScreen(),
    );
  }
}
