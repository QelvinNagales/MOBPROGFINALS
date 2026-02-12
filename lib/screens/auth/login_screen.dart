import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/supabase_service.dart';
import '../home_screen.dart';
import 'register_screen.dart';

/// Login Screen
/// Allows users to sign in with email and password.
/// Horn-In - A student networking and social platform
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  
  static const String _rememberMeKey = 'remember_me';
  static const String _savedEmailKey = 'saved_email';

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool(_rememberMeKey) ?? false;
    final savedEmail = prefs.getString(_savedEmailKey) ?? '';
    
    if (mounted) {
      setState(() {
        _rememberMe = rememberMe;
        if (rememberMe && savedEmail.isNotEmpty) {
          _emailController.text = savedEmail;
        }
      });
    }
  }

  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberMeKey, _rememberMe);
    if (_rememberMe) {
      await prefs.setString(_savedEmailKey, _emailController.text.trim());
    } else {
      await prefs.remove(_savedEmailKey);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    // Clear any previous error messages
    ScaffoldMessenger.of(context).clearSnackBars();
    
    setState(() => _isLoading = true);

    try {
      await SupabaseService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Save credentials if Remember Me is checked
      await _saveCredentials();

      if (!mounted) return;

      // Clear any existing SnackBars before navigating
      ScaffoldMessenger.of(context).clearSnackBars();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image with dark overlay
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: const AssetImage('assets/images/Asia-Pacific-College.jpg'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.6),
                  BlendMode.darken,
                ),
              ),
            ),
          ),
          // Gradient overlay for better text readability
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF1A237E).withOpacity(0.7),
                  const Color(0xFF0D1421).withOpacity(0.85),
                ],
              ),
            ),
          ),
          // Login Form
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: const EdgeInsets.all(32.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E2E).withOpacity(0.85),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // APC Logo
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF3D5AFE).withOpacity(0.4),
                              blurRadius: 25,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/APC.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback logo if image not found
                            return Container(
                              decoration: const BoxDecoration(
                                color: Color(0xFF1A237E),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Text(
                                  'APC',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFD4A51D),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),

                      // App Title
                      const Text(
                        'Horn-In',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Subtitle
                      Text(
                        'Connect, network and socialize\nwith fellow students',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Login Form
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Email Field
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Email Address',
                                hintStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                ),
                                prefixIcon: Icon(
                                  Icons.email_outlined,
                                  color: Colors.white.withOpacity(0.5),
                                ),
                                filled: true,
                                fillColor: const Color(0xFF2D2D3A),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.white.withOpacity(0.1),
                                    width: 1,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFD4A51D),
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!value.contains('@')) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Password Field
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Password',
                                hintStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                ),
                                prefixIcon: Icon(
                                  Icons.lock_outline,
                                  color: Colors.white.withOpacity(0.5),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: Colors.white.withOpacity(0.5),
                                  ),
                                  onPressed: () {
                                    setState(
                                        () => _obscurePassword = !_obscurePassword);
                                  },
                                ),
                                filled: true,
                                fillColor: const Color(0xFF2D2D3A),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.white.withOpacity(0.1),
                                    width: 1,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFD4A51D),
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Remember Me & Forgot Password Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Remember Me Checkbox
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: Checkbox(
                                        value: _rememberMe,
                                        onChanged: (value) {
                                          setState(() => _rememberMe = value!);
                                        },
                                        activeColor: const Color(0xFFD4A51D),
                                        checkColor: Colors.white,
                                        side: BorderSide(
                                          color: Colors.white.withOpacity(0.5),
                                          width: 1.5,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Remember me',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                // Forgot Password
                                TextButton(
                                  onPressed: () => _showForgotPasswordDialog(),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text(
                                    'Forgot Password?',
                                    style: TextStyle(
                                      color: Color(0xFFD4A51D),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Login Button
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _signIn,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFD4A51D),
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor:
                                      const Color(0xFFD4A51D).withOpacity(0.6),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Sign In',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Register Link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Don't have an account? ",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 14,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const RegisterScreen(),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'Register Now',
                                    style: TextStyle(
                                      color: Color(0xFFD4A51D),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Reset Password',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Email',
              labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
              hintText: 'Enter your email address',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              filled: true,
              fillColor: const Color(0xFF2D2D3A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFFD4A51D),
                  width: 2,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.white.withOpacity(0.7)),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (emailController.text.isNotEmpty) {
                  try {
                    await SupabaseService.resetPassword(emailController.text);
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password reset email sent!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4A51D),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Send Reset Link',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}
