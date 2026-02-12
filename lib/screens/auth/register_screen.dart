import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../home_screen.dart';

/// Register Screen
/// Allows users to create a new account.
/// Horn-In - A student networking and social platform
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToTerms = false;
  
  // Password strength
  double _passwordStrength = 0;
  String _passwordStrengthText = '';
  Color _passwordStrengthColor = Colors.grey;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _checkPasswordStrength(String password) {
    double strength = 0;
    String text = '';
    Color color = Colors.grey;

    if (password.isEmpty) {
      setState(() {
        _passwordStrength = 0;
        _passwordStrengthText = '';
        _passwordStrengthColor = Colors.grey;
      });
      return;
    }

    // Length check
    if (password.length >= 6) strength += 0.2;
    if (password.length >= 8) strength += 0.1;
    if (password.length >= 12) strength += 0.1;

    // Contains lowercase
    if (password.contains(RegExp(r'[a-z]'))) strength += 0.15;
    
    // Contains uppercase
    if (password.contains(RegExp(r'[A-Z]'))) strength += 0.15;
    
    // Contains numbers
    if (password.contains(RegExp(r'[0-9]'))) strength += 0.15;
    
    // Contains special characters
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength += 0.15;

    // Set text and color based on strength
    if (strength < 0.3) {
      text = 'Weak';
      color = Colors.red;
    } else if (strength < 0.5) {
      text = 'Fair';
      color = Colors.orange;
    } else if (strength < 0.7) {
      text = 'Good';
      color = Colors.amber;
    } else if (strength < 0.9) {
      text = 'Strong';
      color = Colors.lightGreen;
    } else {
      text = 'Very Strong';
      color = Colors.green;
    }

    setState(() {
      _passwordStrength = strength.clamp(0.0, 1.0);
      _passwordStrengthText = text;
      _passwordStrengthColor = color;
    });
  }

  bool _isValidEmail(String email) {
    // Comprehensive email validation regex
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please agree to the Terms & Conditions'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await SupabaseService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _nameController.text.trim(),
      );

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Account created successfully! Welcome to Horn-In!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      // Navigate to home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration failed: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
          // Registration Form
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  // Back Button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Form Card
                  Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    padding: const EdgeInsets.all(28.0),
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
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF3D5AFE).withOpacity(0.4),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/images/APC.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: const BoxDecoration(
                                  color: Color(0xFF1A237E),
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Text(
                                    'APC',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFD4A51D),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Title
                        const Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Subtitle
                        Text(
                          'Join Horn-In and connect with\nfellow APC students',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.7),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Registration Form
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              // Full Name Field
                              TextFormField(
                                controller: _nameController,
                                style: const TextStyle(color: Colors.white),
                                textCapitalization: TextCapitalization.words,
                                decoration: InputDecoration(
                                  hintText: 'Full Name',
                                  hintStyle: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                  ),
                                  prefixIcon: Icon(
                                    Icons.person_outline,
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
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Colors.red,
                                      width: 1,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter your full name';
                                  }
                                  if (value.trim().length < 2) {
                                    return 'Name must be at least 2 characters';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

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
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Colors.red,
                                      width: 1,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  if (!_isValidEmail(value.trim())) {
                                    return 'Please enter a valid email address';
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
                                onChanged: _checkPasswordStrength,
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
                                      setState(() => _obscurePassword = !_obscurePassword);
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
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Colors.red,
                                      width: 1,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a password';
                                  }
                                  if (value.length < 8) {
                                    return 'Password must be at least 8 characters';
                                  }
                                  if (!value.contains(RegExp(r'[A-Z]'))) {
                                    return 'Include at least one uppercase letter';
                                  }
                                  if (!value.contains(RegExp(r'[a-z]'))) {
                                    return 'Include at least one lowercase letter';
                                  }
                                  if (!value.contains(RegExp(r'[0-9]'))) {
                                    return 'Include at least one number';
                                  }
                                  return null;
                                },
                              ),
                              
                              // Password Strength Indicator
                              if (_passwordController.text.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(4),
                                            child: LinearProgressIndicator(
                                              value: _passwordStrength,
                                              backgroundColor: Colors.white.withOpacity(0.1),
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                _passwordStrengthColor,
                                              ),
                                              minHeight: 6,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          _passwordStrengthText,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: _passwordStrengthColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Use 8+ chars with uppercase, lowercase, numbers & symbols',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.white.withOpacity(0.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 16),

                              // Confirm Password Field
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: _obscureConfirmPassword,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: 'Confirm Password',
                                  hintStyle: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                  ),
                                  prefixIcon: Icon(
                                    Icons.lock_outline,
                                    color: Colors.white.withOpacity(0.5),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirmPassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: Colors.white.withOpacity(0.5),
                                    ),
                                    onPressed: () {
                                      setState(
                                          () => _obscureConfirmPassword = !_obscureConfirmPassword);
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
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Colors.red,
                                      width: 1,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                ),
                                validator: (value) {
                                  if (value != _passwordController.text) {
                                    return 'Passwords do not match';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),

                              // Terms and Conditions Checkbox
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: Checkbox(
                                      value: _agreedToTerms,
                                      onChanged: (value) {
                                        setState(() => _agreedToTerms = value ?? false);
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
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Wrap(
                                      children: [
                                        Text(
                                          'I agree to the ',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.7),
                                            fontSize: 13,
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            // Show terms dialog
                                            _showTermsDialog();
                                          },
                                          child: const Text(
                                            'Terms & Conditions',
                                            style: TextStyle(
                                              color: Color(0xFFD4A51D),
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              decoration: TextDecoration.underline,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Register Button
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _signUp,
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
                                          'Create Account',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Login Link
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Already have an account? ",
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 14,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => Navigator.pop(context),
                                    child: const Text(
                                      'Sign In',
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
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Terms & Conditions',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Text(
            'Welcome to Horn-In!\n\n'
            'By creating an account, you agree to:\n\n'
            '1. Use the platform responsibly and respectfully\n'
            '2. Not share inappropriate or harmful content\n'
            '3. Respect other students\' privacy\n'
            '4. Not misuse the networking features\n'
            '5. Keep your account credentials secure\n'
            '6. Report any violations or concerns\n\n'
            'Horn-In is designed to help APC students connect, '
            'network, and socialize in a safe and productive environment.\n\n'
            'Violation of these terms may result in account suspension.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: Color(0xFFD4A51D)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _agreedToTerms = true);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4A51D),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'I Agree',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
