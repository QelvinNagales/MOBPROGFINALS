import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/theme_service.dart';
import '../models/profile.dart';

/// Modal widget to display and share user's QR code
class QrCodeModal extends StatefulWidget {
  final Profile profile;
  
  const QrCodeModal({
    super.key,
    required this.profile,
  });

  static Future<void> show(BuildContext context, Profile profile) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => QrCodeModal(profile: profile),
    );
  }

  @override
  State<QrCodeModal> createState() => _QrCodeModalState();
}

class _QrCodeModalState extends State<QrCodeModal> {
  final GlobalKey _qrKey = GlobalKey();
  bool _isSaving = false;
  bool _isSharing = false;

  String get _qrData => 'hornin://profile/${widget.profile.id}';

  Future<Uint8List?> _captureQrCode() async {
    try {
      final boundary = _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error capturing QR code: $e');
      return null;
    }
  }

  Future<void> _saveToGallery() async {
    setState(() => _isSaving = true);
    
    try {
      if (kIsWeb) {
        // On web, copy the profile link to clipboard
        await Clipboard.setData(ClipboardData(text: _qrData));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Profile link copied to clipboard!'),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        // On mobile, save to file
        final bytes = await _captureQrCode();
        if (bytes == null) throw Exception('Failed to capture QR code');
        
        final directory = await getApplicationDocumentsDirectory();
        final fileName = 'hornin_qr_${widget.profile.id}_${DateTime.now().millisecondsSinceEpoch}.png';
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(bytes);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('QR code saved successfully!'),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _shareQrCode() async {
    setState(() => _isSharing = true);
    
    try {
      if (kIsWeb) {
        // On web, share via Share API or copy link
        await Share.share(
          'Scan this QR code to connect with ${widget.profile.fullName} on Horn-In!\n$_qrData',
          subject: 'Connect on Horn-In',
        );
      } else {
        // On mobile, share as image
        final bytes = await _captureQrCode();
        if (bytes == null) throw Exception('Failed to capture QR code');
        
        final directory = await getTemporaryDirectory();
        final fileName = 'hornin_qr_${widget.profile.fullName.replaceAll(' ', '_')}.png';
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(bytes);
        
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Scan this QR code to connect with ${widget.profile.fullName} on Horn-In!',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share: $e'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Title
          Text(
            'My QR Code',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.darkText,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Let others scan to connect with you',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white60 : AppColors.darkText.withOpacity(0.6),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // QR Code with profile picture
          RepaintBoundary(
            key: _qrKey,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGold.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      QrImageView(
                        data: _qrData,
                        version: QrVersions.auto,
                        size: 200,
                        backgroundColor: Colors.white,
                        eyeStyle: QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: AppColors.primaryNavy,
                        ),
                        dataModuleStyle: QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                      // Profile picture in center
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: widget.profile.avatarUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: widget.profile.avatarUrl!,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => _buildAvatarPlaceholder(),
                                  errorWidget: (_, __, ___) => _buildAvatarPlaceholder(),
                                )
                              : _buildAvatarPlaceholder(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // User name
                  Text(
                    widget.profile.fullName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkText,
                    ),
                  ),
                  if (widget.profile.course != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.profile.course!,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.darkText.withOpacity(0.6),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.save_alt_rounded,
                    label: 'Save',
                    onTap: _saveToGallery,
                    isLoading: _isSaving,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.share_rounded,
                    label: 'Share',
                    onTap: _shareQrCode,
                    isLoading: _isSharing,
                    isDark: isDark,
                    isPrimary: true,
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
        ],
      ),
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Container(
      color: AppColors.primaryGold.withOpacity(0.2),
      child: Icon(
        Icons.person_rounded,
        size: 30,
        color: AppColors.primaryGold,
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
    bool isLoading = false,
    bool isPrimary = false,
  }) {
    return Material(
      color: isPrimary 
          ? AppColors.primaryGold 
          : (isDark ? Colors.white12 : Colors.grey.shade100),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: isPrimary ? Colors.white : AppColors.primaryGold,
                  ),
                )
              else
                Icon(
                  icon,
                  size: 20,
                  color: isPrimary 
                      ? Colors.white 
                      : (isDark ? Colors.white70 : AppColors.darkText),
                ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isPrimary 
                      ? Colors.white 
                      : (isDark ? Colors.white70 : AppColors.darkText),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
