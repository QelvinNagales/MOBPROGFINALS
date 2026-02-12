import 'package:flutter/material.dart';
import '../main.dart' show themeService;
import '../services/theme_service.dart';
import '../services/supabase_service.dart';
import 'auth/login_screen.dart';

/// Settings Screen - Bumble-Inspired Design
/// App settings and preferences with dark mode support
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Settings state
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _profilePublic = true;
  bool _showOnlineStatus = true;
  String _selectedLanguage = 'English';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await SupabaseService.getUserSettings();
      if (settings != null && mounted) {
        setState(() {
          _notificationsEnabled = settings['push_notifications'] ?? true;
          _emailNotifications = settings['email_notifications'] ?? true;
          _profilePublic = settings['show_email'] ?? true;
          _showOnlineStatus = settings['show_online_status'] ?? true;
          _selectedLanguage = settings['language'] == 'en' ? 'English' : settings['language'] ?? 'English';
        });
      }
    } catch (e) {
      // Ignore errors loading settings
    }
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    try {
      await SupabaseService.updateUserSettings({key: value});
    } catch (e) {
      // Ignore errors
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.grey,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Account Section
          _buildSectionCard(
            title: 'Account',
            icon: Icons.person_rounded,
            isDark: isDark,
            children: [
              _buildListTile(
                icon: Icons.edit_rounded,
                title: 'Edit Profile',
                subtitle: 'Update your personal information',
                isDark: isDark,
                onTap: () {
                  Navigator.pop(context); // Go back to profile
                },
              ),
              _buildDivider(isDark),
              _buildListTile(
                icon: Icons.lock_rounded,
                title: 'Change Password',
                subtitle: 'Update your password',
                isDark: isDark,
                onTap: () => _showChangePasswordDialog(),
              ),
              _buildDivider(isDark),
              _buildListTile(
                icon: Icons.email_rounded,
                title: 'Email',
                subtitle: SupabaseService.currentUser?.email ?? 'Not set',
                showArrow: false,
                isDark: isDark,
                onTap: () {},
              ),
            ],
          ),
          
          const SizedBox(height: 16),

          // Privacy Section
          _buildSectionCard(
            title: 'Privacy',
            icon: Icons.shield_rounded,
            isDark: isDark,
            children: [
              _buildSwitchTile(
                icon: Icons.public_rounded,
                title: 'Public Profile',
                subtitle: 'Allow others to view your profile',
                value: _profilePublic,
                isDark: isDark,
                onChanged: (value) {
                  setState(() => _profilePublic = value);
                  _updateSetting('show_email', value);
                },
              ),
              _buildDivider(isDark),
              _buildSwitchTile(
                icon: Icons.circle_rounded,
                title: 'Show Online Status',
                subtitle: 'Let others see when you are online',
                value: _showOnlineStatus,
                isDark: isDark,
                onChanged: (value) {
                  setState(() => _showOnlineStatus = value);
                  _updateSetting('show_online_status', value);
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Notifications Section
          _buildSectionCard(
            title: 'Notifications',
            icon: Icons.notifications_rounded,
            isDark: isDark,
            children: [
              _buildSwitchTile(
                icon: Icons.notifications_active_rounded,
                title: 'Push Notifications',
                subtitle: 'Receive push notifications',
                value: _notificationsEnabled,
                isDark: isDark,
                onChanged: (value) {
                  setState(() => _notificationsEnabled = value);
                  _updateSetting('push_notifications', value);
                },
              ),
              _buildDivider(isDark),
              _buildSwitchTile(
                icon: Icons.email_outlined,
                title: 'Email Notifications',
                subtitle: 'Receive email notifications',
                value: _emailNotifications,
                isDark: isDark,
                onChanged: (value) {
                  setState(() => _emailNotifications = value);
                  _updateSetting('email_notifications', value);
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Appearance Section - with working Dark Mode!
          _buildSectionCard(
            title: 'Appearance',
            icon: Icons.palette_rounded,
            headerColor: AppColors.primaryBlue,
            isDark: isDark,
            children: [
              _buildThemeSwitchTile(isDark),
              _buildDivider(isDark),
              _buildListTile(
                icon: Icons.language_rounded,
                title: 'Language',
                subtitle: _selectedLanguage,
                isDark: isDark,
                onTap: () => _showLanguageDialog(),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // About Section
          _buildSectionCard(
            title: 'About',
            icon: Icons.info_rounded,
            isDark: isDark,
            children: [
              _buildListTile(
                icon: Icons.info_outline_rounded,
                title: 'About App',
                subtitle: 'Version 1.0.0',
                isDark: isDark,
                onTap: () => _showAboutDialog(),
              ),
              _buildDivider(isDark),
              _buildListTile(
                icon: Icons.description_rounded,
                title: 'Terms of Service',
                isDark: isDark,
                onTap: () {},
              ),
              _buildDivider(isDark),
              _buildListTile(
                icon: Icons.privacy_tip_rounded,
                title: 'Privacy Policy',
                isDark: isDark,
                onTap: () {},
              ),
              _buildDivider(isDark),
              _buildListTile(
                icon: Icons.help_rounded,
                title: 'Help & Support',
                isDark: isDark,
                onTap: () {},
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Danger Zone
          _buildSectionCard(
            title: 'Danger Zone',
            icon: Icons.warning_rounded,
            headerColor: AppColors.error,
            isDark: isDark,
            children: [
              _buildListTile(
                icon: Icons.logout_rounded,
                title: 'Sign Out',
                iconColor: AppColors.warning,
                isDark: isDark,
                onTap: () => _showSignOutDialog(),
              ),
              _buildDivider(isDark),
              _buildListTile(
                icon: Icons.delete_forever_rounded,
                title: 'Delete Account',
                iconColor: AppColors.error,
                textColor: AppColors.error,
                isDark: isDark,
                onTap: () => _showDeleteAccountDialog(),
              ),
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildThemeSwitchTile(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1a1a2e) : AppColors.primaryBlue,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              size: 18,
              color: isDark ? AppColors.primaryBlue : Colors.white,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dark Mode',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isDark ? 'Currently using dark theme' : 'Switch to dark theme',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isDark,
            onChanged: (value) {
              themeService.setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
            },
            activeColor: AppColors.primaryBlue,
            activeTrackColor: AppColors.primaryBlue.withOpacity(0.3),
            inactiveThumbColor: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            inactiveTrackColor: isDark ? AppColors.darkCardBorder : AppColors.cardBorder,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
    required bool isDark,
    Color? headerColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : AppColors.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (headerColor ?? AppColors.primaryBlue).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: headerColor ?? AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: headerColor ?? (isDark ? AppColors.darkTextPrimary : AppColors.primaryBlue),
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
          ...children,
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      height: 1,
      color: isDark ? AppColors.darkCardBorder : AppColors.cardBorder,
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? iconColor,
    Color? textColor,
    bool showArrow = true,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (iconColor ?? (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary)).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 18,
                color: iconColor ?? (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textColor ?? (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (showArrow)
              Icon(
                Icons.chevron_right_rounded,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required bool isDark,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 18,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primaryBlue,
            activeTrackColor: AppColors.primaryBlue.withOpacity(0.3),
            inactiveThumbColor: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            inactiveTrackColor: isDark ? AppColors.darkCardBorder : AppColors.cardBorder,
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Change Password',
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        content: Text(
          'A password reset link will be sent to your email.',
          style: TextStyle(
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await SupabaseService.resetPassword(SupabaseService.currentUser?.email ?? '');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password reset email sent!')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Send Reset Link'),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final languages = ['English', 'Filipino', 'Spanish'];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Select Language',
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: languages.map((lang) {
            final isSelected = lang == _selectedLanguage;
            return ListTile(
              title: Text(
                lang,
                style: TextStyle(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              leading: Icon(
                isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                color: isSelected ? AppColors.primaryBlue : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
              ),
              onTap: () {
                setState(() => _selectedLanguage = lang);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showAboutDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.school_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'APC Student Network',
                    style: TextStyle(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    'Version 1.0.0',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Text(
          'A Bumble-inspired student networking platform for Asia Pacific College. '
          'Connect with fellow students, find compatible groupmates, and showcase your projects.',
          style: TextStyle(
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: AppColors.primaryBlue),
            ),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Sign Out',
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to sign out?',
          style: TextStyle(
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              setState(() => _isLoading = true);
              try {
                await SupabaseService.signOut();
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error signing out: $e')),
                  );
                }
              }
              setState(() => _isLoading = false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.warning_rounded, color: AppColors.error),
            ),
            const SizedBox(width: 12),
            Text(
              'Delete Account',
              style: TextStyle(
                color: AppColors.error,
              ),
            ),
          ],
        ),
        content: Text(
          'This action cannot be undone. All your data including profile, '
          'projects, and connections will be permanently deleted.',
          style: TextStyle(
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showPasswordConfirmationDialog();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _showPasswordConfirmationDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final passwordController = TextEditingController();
    bool isLoading = false;
    bool obscurePassword = true;
    String? errorMessage;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: isDark ? AppColors.darkCard : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.lock_rounded, color: AppColors.error),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Confirm Password',
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.darkText,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter your password to permanently delete your account.',
                style: TextStyle(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: passwordController,
                obscureText: obscurePassword,
                enabled: !isLoading,
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: TextStyle(
                    color: isDark ? Colors.white54 : AppColors.textSecondary,
                  ),
                  prefixIcon: Icon(
                    Icons.lock_outline,
                    color: isDark ? Colors.white54 : AppColors.textSecondary,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: isDark ? Colors.white54 : AppColors.textSecondary,
                    ),
                    onPressed: () => setState(() => obscurePassword = !obscurePassword),
                  ),
                  filled: true,
                  fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  errorText: errorMessage,
                  errorStyle: const TextStyle(color: AppColors.error),
                ),
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.darkText,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                if (passwordController.text.isEmpty) {
                  setState(() => errorMessage = 'Please enter your password');
                  return;
                }
                
                setState(() {
                  isLoading = true;
                  errorMessage = null;
                });
                
                final result = await SupabaseService.deleteAccountWithPassword(
                  passwordController.text,
                );
                
                if (!mounted) return;
                
                if (result.success) {
                  Navigator.pop(context); // Close password dialog
                  
                  // Navigate to splash screen
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/',
                    (route) => false,
                  );
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Your account has been permanently deleted'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 4),
                    ),
                  );
                } else {
                  setState(() {
                    isLoading = false;
                    errorMessage = result.error ?? 'Failed to delete account';
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Delete Permanently'),
            ),
          ],
        ),
      ),
    );
  }
}
