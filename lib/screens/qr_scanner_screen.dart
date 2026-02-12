import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/theme_service.dart';
import '../services/supabase_service.dart';
import '../models/profile.dart';
import 'profile_screen.dart';

/// QR Scanner screen to scan other users' profiles
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  
  bool _isProcessing = false;
  bool _hasScanned = false;
  String? _lastScannedCode;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing || _hasScanned) return;
    
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;
    
    final code = barcode.rawValue!;
    
    // Check if it's a Horn-In profile link
    if (!code.startsWith('hornin://profile/')) {
      _showError('Invalid QR code. Please scan a Horn-In profile QR code.');
      return;
    }
    
    // Extract user ID
    final userId = code.replaceFirst('hornin://profile/', '');
    if (userId.isEmpty || userId == _lastScannedCode) return;
    
    setState(() {
      _isProcessing = true;
      _hasScanned = true;
      _lastScannedCode = userId;
    });
    
    try {
      // Fetch the scanned user's profile
      final profileData = await SupabaseService.getProfileById(userId);
      
      if (profileData == null) {
        _showError('User not found');
        _resetScanner();
        return;
      }
      
      final profile = Profile.fromJson(profileData);
      
      // Check if it's the current user
      if (userId == SupabaseService.userId) {
        _showError("That's your own profile!");
        _resetScanner();
        return;
      }
      
      if (mounted) {
        // Navigate to the scanned user's profile
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileScreen(
              profile: profile,
              showBackButton: true,
            ),
          ),
        );
      }
    } catch (e) {
      _showError('Error loading profile: $e');
      _resetScanner();
    }
  }

  void _resetScanner() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _hasScanned = false;
        });
      }
    });
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera view
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          
          // Overlay with scan area
          _buildScanOverlay(),
          
          // Top bar
          _buildTopBar(),
          
          // Bottom instructions
          _buildBottomInstructions(),
          
          // Loading indicator
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Loading profile...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScanOverlay() {
    return CustomPaint(
      painter: _ScanOverlayPainter(),
      child: Container(),
    );
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Close button
            _buildCircleButton(
              icon: Icons.close_rounded,
              onTap: () => Navigator.pop(context),
            ),
            
            // Title
            const Text(
              'Scan QR Code',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            // Flash toggle
            _buildCircleButton(
              icon: _controller.torchEnabled 
                  ? Icons.flash_on_rounded 
                  : Icons.flash_off_rounded,
              onTap: () => _controller.toggleTorch(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.black38,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
      ),
    );
  }

  Widget _buildBottomInstructions() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).padding.bottom + 24,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.8),
            ],
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primaryGold.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primaryGold.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.qr_code_scanner_rounded, 
                      color: AppColors.primaryGold, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Point camera at a Horn-In QR code',
                    style: TextStyle(
                      color: AppColors.primaryGold,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Scan a friend\'s QR code to instantly view their profile and connect with them',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for scan overlay with rounded rectangle cutout
class _ScanOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.fill;
    
    // Calculate scan area (centered square)
    final scanSize = size.width * 0.7;
    final scanRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2 - 50),
      width: scanSize,
      height: scanSize,
    );
    
    // Draw overlay with cutout
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(24)))
      ..fillType = PathFillType.evenOdd;
    
    canvas.drawPath(path, paint);
    
    // Draw corner brackets
    final bracketPaint = Paint()
      ..color = AppColors.primaryGold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    
    const bracketLength = 30.0;
    const cornerRadius = 24.0;
    
    // Top-left corner
    canvas.drawPath(
      Path()
        ..moveTo(scanRect.left, scanRect.top + bracketLength + cornerRadius)
        ..lineTo(scanRect.left, scanRect.top + cornerRadius)
        ..arcToPoint(
          Offset(scanRect.left + cornerRadius, scanRect.top),
          radius: const Radius.circular(cornerRadius),
        )
        ..lineTo(scanRect.left + bracketLength + cornerRadius, scanRect.top),
      bracketPaint,
    );
    
    // Top-right corner
    canvas.drawPath(
      Path()
        ..moveTo(scanRect.right - bracketLength - cornerRadius, scanRect.top)
        ..lineTo(scanRect.right - cornerRadius, scanRect.top)
        ..arcToPoint(
          Offset(scanRect.right, scanRect.top + cornerRadius),
          radius: const Radius.circular(cornerRadius),
        )
        ..lineTo(scanRect.right, scanRect.top + bracketLength + cornerRadius),
      bracketPaint,
    );
    
    // Bottom-right corner
    canvas.drawPath(
      Path()
        ..moveTo(scanRect.right, scanRect.bottom - bracketLength - cornerRadius)
        ..lineTo(scanRect.right, scanRect.bottom - cornerRadius)
        ..arcToPoint(
          Offset(scanRect.right - cornerRadius, scanRect.bottom),
          radius: const Radius.circular(cornerRadius),
        )
        ..lineTo(scanRect.right - bracketLength - cornerRadius, scanRect.bottom),
      bracketPaint,
    );
    
    // Bottom-left corner
    canvas.drawPath(
      Path()
        ..moveTo(scanRect.left + bracketLength + cornerRadius, scanRect.bottom)
        ..lineTo(scanRect.left + cornerRadius, scanRect.bottom)
        ..arcToPoint(
          Offset(scanRect.left, scanRect.bottom - cornerRadius),
          radius: const Radius.circular(cornerRadius),
        )
        ..lineTo(scanRect.left, scanRect.bottom - bracketLength - cornerRadius),
      bracketPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
