import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/theme_service.dart';
import '../models/profile.dart';

/// Modal to share profile via various methods
class ShareProfileModal extends StatefulWidget {
  final Profile profile;
  
  const ShareProfileModal({
    super.key,
    required this.profile,
  });

  static Future<void> show(BuildContext context, Profile profile) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ShareProfileModal(profile: profile),
    );
  }

  @override
  State<ShareProfileModal> createState() => _ShareProfileModalState();
}

class _ShareProfileModalState extends State<ShareProfileModal> {
  final GlobalKey _cardKey = GlobalKey();
  bool _isGeneratingCard = false;

  String get _profileLink => 'hornin://profile/${widget.profile.id}';
  
  String get _shareText => '''
Check out ${widget.profile.fullName}'s profile on Horn-In!
${widget.profile.course != null ? '${widget.profile.course}\n' : ''}
Connect with them: $_profileLink
''';

  Future<void> _copyLink() async {
    await Clipboard.setData(ClipboardData(text: _profileLink));
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Profile link copied!'),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _shareViaApps() async {
    await Share.share(
      _shareText,
      subject: 'Connect with ${widget.profile.fullName} on Horn-In',
    );
  }

  Future<void> _shareAsCard() async {
    setState(() => _isGeneratingCard = true);
    
    try {
      if (kIsWeb) {
        // On web, share text with profile link
        await Share.share(
          'Connect with ${widget.profile.fullName} on Horn-In!\n$_profileLink',
          subject: 'Horn-In Profile',
        );
      } else {
        // Wait for card to render
        await Future.delayed(const Duration(milliseconds: 100));
        
        final boundary = _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
        if (boundary == null) throw Exception('Could not capture card');
        
        final image = await boundary.toImage(pixelRatio: 3.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData == null) throw Exception('Could not generate image');
        
        final bytes = byteData.buffer.asUint8List();
        final directory = await getTemporaryDirectory();
        final fileName = 'hornin_profile_${widget.profile.fullName.replaceAll(' ', '_')}.png';
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(bytes);
        
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Connect with ${widget.profile.fullName} on Horn-In!',
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
      if (mounted) setState(() => _isGeneratingCard = false);
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
            'Share Profile',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.darkText,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Share options
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                _buildShareOption(
                  icon: Icons.copy_rounded,
                  label: 'Copy Link',
                  subtitle: 'Copy profile link to clipboard',
                  onTap: _copyLink,
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _buildShareOption(
                  icon: Icons.share_rounded,
                  label: 'Share via Apps',
                  subtitle: 'Share to WhatsApp, Messenger, etc.',
                  onTap: _shareViaApps,
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _buildShareOption(
                  icon: Icons.image_rounded,
                  label: 'Share as Card',
                  subtitle: 'Share a visual profile card image',
                  onTap: _shareAsCard,
                  isDark: isDark,
                  isLoading: _isGeneratingCard,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Profile card preview (hidden, used for capture)
          Offstage(
            offstage: !_isGeneratingCard,
            child: RepaintBoundary(
              key: _cardKey,
              child: _ProfileCard(profile: widget.profile),
            ),
          ),
          
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  Widget _buildShareOption({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
    bool isLoading = false,
  }) {
    return Material(
      color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryGold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: isLoading 
                    ? Padding(
                        padding: const EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primaryGold,
                        ),
                      )
                    : Icon(icon, color: AppColors.primaryGold, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.darkText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : AppColors.darkText.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: isDark ? Colors.white30 : Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Visual profile card for sharing as image
class _ProfileCard extends StatelessWidget {
  final Profile profile;
  
  const _ProfileCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 350,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryNavy,
            AppColors.primaryNavy.withOpacity(0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with branding
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primaryGold,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        'H',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Horn-In',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryGold.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primaryGold.withOpacity(0.3)),
                ),
                child: const Text(
                  'APC Student',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Profile picture
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primaryGold, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: profile.avatarUrl != null
                  ? CachedNetworkImage(
                      imageUrl: profile.avatarUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _buildAvatarPlaceholder(),
                      errorWidget: (_, __, ___) => _buildAvatarPlaceholder(),
                    )
                  : _buildAvatarPlaceholder(),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Name
          Text(
            profile.fullName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          
          if (profile.course != null) ...[
            const SizedBox(height: 6),
            Text(
              profile.course!,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          
          const SizedBox(height: 20),
          
          // QR Code
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: QrImageView(
              data: 'hornin://profile/${profile.id}',
              version: QrVersions.auto,
              size: 100,
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
          ),
          
          const SizedBox(height: 16),
          
          // Scan to connect text
          Text(
            'Scan to connect',
            style: TextStyle(
              color: AppColors.primaryGold,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Container(
      color: AppColors.primaryGold.withOpacity(0.3),
      child: Icon(
        Icons.person_rounded,
        size: 40,
        color: AppColors.primaryGold,
      ),
    );
  }
}
