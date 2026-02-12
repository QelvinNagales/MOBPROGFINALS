import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import 'auth/login_screen.dart';
import 'home_screen.dart';

/// Splash Screen
/// Displays the app logo while checking authentication status.
/// Horn-In - A student networking and social platform
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Wait for animation and minimum splash duration
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    // Clear any existing SnackBars from previous sessions
    ScaffoldMessenger.of(context).clearSnackBars();

    // Check if user is logged in
    if (SupabaseService.isLoggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A237E), // Deep navy blue
              Color(0xFF0D1421), // Dark navy
            ],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // APC Logo with scale animation
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF3D5AFE).withOpacity(0.5),
                              blurRadius: 40,
                              spreadRadius: 15,
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
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFD4A51D),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // App Name with slide animation
                    Transform.translate(
                      offset: Offset(0, _slideAnimation.value),
                      child: Column(
                        children: [
                          const Text(
                            'Horn-In',
                            style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Connect • Network • Socialize',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withOpacity(0.7),
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 60),
                    // Loading indicator
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          const Color(0xFFD4A51D).withOpacity(_fadeAnimation.value),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
