import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme Service - Manages app theme state with persistence
/// Provides dark mode functionality with Bumble-inspired color palette
class ThemeService extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  ThemeService() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString(_themeKey) ?? 'system';
    _themeMode = _stringToThemeMode(themeString);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, _themeModeToString(mode));
    notifyListeners();
  }

  Future<void> toggleDarkMode() async {
    if (_themeMode == ThemeMode.dark) {
      await setThemeMode(ThemeMode.light);
    } else {
      await setThemeMode(ThemeMode.dark);
    }
  }

  ThemeMode _stringToThemeMode(String value) {
    switch (value) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      default:
        return ThemeMode.system;
    }
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.light:
        return 'light';
      case ThemeMode.system:
        return 'system';
    }
  }
}

/// App Colors - Original Blue/Purple Theme
class AppColors {
  // Primary Colors - Blue/Purple Theme
  static const Color primaryYellow = Color(0xFFFFD700);
  static const Color primaryBlue = Color(0xFF3D3D8F);
  static const Color primaryGold = Color(0xFFD4C84D);
  static const Color bumbleYellow = Color(0xFF3D3D8F); // Now uses primaryBlue for consistency
  static const Color accentPink = Color(0xFFFF6B6B);
  static const Color accentPurple = Color(0xFF7C4DFF);

  // Light Theme Colors
  static const Color lightBlue = Color(0xFFF0F0FA);
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color accentBlue = Color(0xFFE8E8F5);
  static const Color white = Colors.white;
  static const Color grey = Color(0xFFF8F9FA);
  static const Color darkGrey = Color(0xFF6B7280);
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color cardBorder = Color(0xFFE5E7EB);
  static const Color darkText = Color(0xFF1F2937);
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkCard = Color(0xFF2D2D2D);
  static const Color darkCardBorder = Color(0xFF404040);
  static const Color darkTextPrimary = Color(0xFFF3F4F6);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);
}

/// Light Theme Data
ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  fontFamily: 'Inter',
  brightness: Brightness.light,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primaryBlue,
    primary: AppColors.primaryBlue,
    secondary: AppColors.primaryBlue,
    surface: Colors.white,
    surfaceContainerHighest: AppColors.grey,
    brightness: Brightness.light,
  ),
  scaffoldBackgroundColor: AppColors.grey,
  appBarTheme: const AppBarTheme(
    centerTitle: false,
    elevation: 0,
    scrolledUnderElevation: 0,
    backgroundColor: Colors.transparent,
    foregroundColor: AppColors.textPrimary,
    iconTheme: IconThemeData(color: AppColors.primaryBlue),
    titleTextStyle: TextStyle(
      color: AppColors.textPrimary,
      fontSize: 20,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.5,
    ),
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    color: Colors.white,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: AppColors.cardBorder, width: 1),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primaryBlue,
      foregroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25),
      ),
      textStyle: const TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 16,
        letterSpacing: -0.2,
      ),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.primaryBlue,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      side: const BorderSide(color: AppColors.primaryBlue, width: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25),
      ),
      textStyle: const TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 16,
        letterSpacing: -0.2,
      ),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primaryBlue,
      textStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
    ),
  ),
  navigationBarTheme: NavigationBarThemeData(
    height: 75,
    elevation: 0,
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    indicatorColor: AppColors.primaryBlue.withOpacity(0.2),
    labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    iconTheme: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const IconThemeData(color: AppColors.primaryBlue, size: 26);
      }
      return const IconThemeData(color: AppColors.darkGrey, size: 24);
    }),
    labelTextStyle: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const TextStyle(
          color: AppColors.primaryBlue,
          fontWeight: FontWeight.w700,
          fontSize: 11,
          letterSpacing: -0.2,
        );
      }
      return const TextStyle(
        color: AppColors.darkGrey,
        fontWeight: FontWeight.w500,
        fontSize: 11,
        letterSpacing: -0.2,
      );
    }),
  ),
  chipTheme: ChipThemeData(
    backgroundColor: AppColors.lightBlue,
    labelStyle: const TextStyle(
      color: AppColors.primaryBlue,
      fontWeight: FontWeight.w600,
      fontSize: 13,
    ),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(25),
    ),
    side: BorderSide.none,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.cardBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.cardBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
    ),
    hintStyle: const TextStyle(color: AppColors.darkGrey, fontSize: 15),
  ),
  dividerTheme: const DividerThemeData(
    color: AppColors.cardBorder,
    thickness: 1,
    space: 1,
  ),
  textTheme: const TextTheme(
    headlineLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w800,
      color: AppColors.textPrimary,
      letterSpacing: -1,
    ),
    headlineMedium: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
      letterSpacing: -0.5,
    ),
    headlineSmall: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
      letterSpacing: -0.5,
    ),
    titleLarge: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
      letterSpacing: -0.3,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
      letterSpacing: -0.2,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: AppColors.textPrimary,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: AppColors.textSecondary,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: AppColors.textSecondary,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
      letterSpacing: -0.2,
    ),
  ),
);

/// Dark Theme Data
ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  fontFamily: 'Inter',
  brightness: Brightness.dark,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primaryBlue,
    primary: AppColors.primaryBlue,
    secondary: AppColors.primaryBlue,
    surface: AppColors.darkSurface,
    surfaceContainerHighest: AppColors.darkCard,
    brightness: Brightness.dark,
  ),
  scaffoldBackgroundColor: AppColors.darkBackground,
  appBarTheme: const AppBarTheme(
    centerTitle: false,
    elevation: 0,
    scrolledUnderElevation: 0,
    backgroundColor: Colors.transparent,
    foregroundColor: AppColors.darkTextPrimary,
    iconTheme: IconThemeData(color: AppColors.primaryBlue),
    titleTextStyle: TextStyle(
      color: AppColors.darkTextPrimary,
      fontSize: 20,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.5,
    ),
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    color: AppColors.darkCard,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: AppColors.darkCardBorder, width: 1),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primaryBlue,
      foregroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25),
      ),
      textStyle: const TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 16,
        letterSpacing: -0.2,
      ),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.primaryBlue,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      side: const BorderSide(color: AppColors.primaryBlue, width: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25),
      ),
      textStyle: const TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 16,
        letterSpacing: -0.2,
      ),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primaryBlue,
      textStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
    ),
  ),
  navigationBarTheme: NavigationBarThemeData(
    height: 75,
    elevation: 0,
    backgroundColor: AppColors.darkSurface,
    surfaceTintColor: Colors.transparent,
    indicatorColor: AppColors.primaryBlue.withOpacity(0.2),
    labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    iconTheme: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const IconThemeData(color: AppColors.primaryBlue, size: 26);
      }
      return const IconThemeData(color: AppColors.darkTextSecondary, size: 24);
    }),
    labelTextStyle: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const TextStyle(
          color: AppColors.primaryBlue,
          fontWeight: FontWeight.w700,
          fontSize: 11,
          letterSpacing: -0.2,
        );
      }
      return const TextStyle(
        color: AppColors.darkTextSecondary,
        fontWeight: FontWeight.w500,
        fontSize: 11,
        letterSpacing: -0.2,
      );
    }),
  ),
  chipTheme: ChipThemeData(
    backgroundColor: AppColors.darkCard,
    labelStyle: const TextStyle(
      color: AppColors.primaryBlue,
      fontWeight: FontWeight.w600,
      fontSize: 13,
    ),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(25),
    ),
    side: const BorderSide(color: AppColors.darkCardBorder),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.darkCard,
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.darkCardBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.darkCardBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
    ),
    hintStyle: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 15),
  ),
  dividerTheme: const DividerThemeData(
    color: AppColors.darkCardBorder,
    thickness: 1,
    space: 1,
  ),
  textTheme: const TextTheme(
    headlineLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w800,
      color: AppColors.darkTextPrimary,
      letterSpacing: -1,
    ),
    headlineMedium: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color: AppColors.darkTextPrimary,
      letterSpacing: -0.5,
    ),
    headlineSmall: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: AppColors.darkTextPrimary,
      letterSpacing: -0.5,
    ),
    titleLarge: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: AppColors.darkTextPrimary,
      letterSpacing: -0.3,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: AppColors.darkTextPrimary,
      letterSpacing: -0.2,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: AppColors.darkTextPrimary,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: AppColors.darkTextSecondary,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: AppColors.darkTextSecondary,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppColors.darkTextPrimary,
      letterSpacing: -0.2,
    ),
  ),
);
