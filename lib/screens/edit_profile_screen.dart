import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../services/theme_service.dart';
import '../models/profile.dart';
import '../services/supabase_service.dart';

/// Edit Profile Screen
/// Provides a form for the user to edit their profile information.
/// Includes fields for pronouns, social links, skills, and projects.
class EditProfileScreen extends StatefulWidget {
  final Profile profile;

  const EditProfileScreen({super.key, required this.profile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  bool _isUploadingImage = false;

  // Profile picture state
  Uint8List? _selectedImageBytes;
  String? _currentAvatarUrl;

  // Text editing controllers
  late TextEditingController _nameController;
  late TextEditingController _pronounsController;
  late TextEditingController _bioController;
  late TextEditingController _emailController;
  late TextEditingController _facebookController;
  late TextEditingController _linkedinController;
  late TextEditingController _skillsController;
  late TextEditingController _projectsController;

  @override
  void initState() {
    super.initState();
    _currentAvatarUrl = widget.profile.avatarUrl;
    _nameController = TextEditingController(text: widget.profile.fullName);
    _pronounsController = TextEditingController(text: widget.profile.pronouns);
    _bioController = TextEditingController(text: widget.profile.bio);
    _emailController = TextEditingController(text: widget.profile.email);
    _facebookController = TextEditingController(text: widget.profile.facebookUsername);
    _linkedinController = TextEditingController(text: widget.profile.linkedinUsername);
    _skillsController = TextEditingController(text: widget.profile.skills.join(', '));
    _projectsController = TextEditingController(text: widget.profile.projects.join(', '));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pronounsController.dispose();
    _bioController.dispose();
    _emailController.dispose();
    _facebookController.dispose();
    _linkedinController.dispose();
    _skillsController.dispose();
    _projectsController.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    final ImagePicker picker = ImagePicker();
    
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() => _isUploadingImage = true);
        
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _isUploadingImage = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingImage = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // Upload profile picture if selected
      String? avatarUrl = _currentAvatarUrl;
      if (_selectedImageBytes != null) {
        try {
          final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final uploadedUrl = await SupabaseService.uploadProfilePicture(
            _selectedImageBytes!,
            fileName,
          );
          if (uploadedUrl != null) {
            avatarUrl = uploadedUrl;
          }
        } catch (e) {
          debugPrint('Image upload failed: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Image upload failed: $e'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }

      final updatedProfile = Profile(
        id: widget.profile.id,
        fullName: _nameController.text.trim(),
        pronouns: _pronounsController.text.trim(),
        bio: _bioController.text.trim(),
        email: _emailController.text.trim(),
        facebookUsername: _facebookController.text.trim(),
        linkedinUsername: _linkedinController.text.trim(),
        socialLink: widget.profile.socialLink,
        avatarUrl: avatarUrl,
        followersCount: widget.profile.followersCount,
        followingCount: widget.profile.followingCount,
        skills: _skillsController.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
        projects: _projectsController.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
      );

      // Try to save to Supabase if user is authenticated
      try {
        await SupabaseService.updateProfile(updatedProfile.toJson());
      } catch (e) {
        // Continue with local update if Supabase fails
        debugPrint('Supabase update failed: $e');
      }

      if (mounted) {
        Navigator.pop(context, updatedProfile);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Profile Picture Section
              Center(
                child: GestureDetector(
                  onTap: _isUploadingImage ? null : _pickProfileImage,
                  child: Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primaryBlue, width: 3),
                          color: AppColors.lightBlue,
                        ),
                        child: _isUploadingImage
                            ? const Center(
                                child: CircularProgressIndicator(),
                              )
                            : _selectedImageBytes != null
                                ? ClipOval(
                                    child: Image.memory(
                                      _selectedImageBytes!,
                                      fit: BoxFit.cover,
                                      width: 120,
                                      height: 120,
                                    ),
                                  )
                                : _currentAvatarUrl != null
                                    ? ClipOval(
                                        child: Image.network(
                                          _currentAvatarUrl!,
                                          fit: BoxFit.cover,
                                          width: 120,
                                          height: 120,
                                          errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(),
                                        ),
                                      )
                                    : _buildAvatarPlaceholder(),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: AppColors.primaryBlue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Tap to change photo',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Full Name
              _buildTextField(
                controller: _nameController,
                label: 'Full Name',
                hint: 'Enter your full name',
                icon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Full name is required';
                  }
                  return null;
                },
              ),

              // Pronouns
              _buildTextField(
                controller: _pronounsController,
                label: 'Pronouns',
                hint: 'e.g., he/him, she/her, they/them',
                icon: Icons.badge_outlined,
              ),

              // Bio
              _buildTextField(
                controller: _bioController,
                label: 'Short Bio',
                hint: 'Tell us about yourself',
                icon: Icons.info_outline,
                maxLines: 3,
              ),

              // Email
              _buildTextField(
                controller: _emailController,
                label: 'Email',
                hint: 'Enter your email address',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value != null && value.isNotEmpty && !value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),

              // Facebook Username
              _buildTextField(
                controller: _facebookController,
                label: 'Facebook Username',
                hint: 'Your Facebook username',
                iconData: FontAwesomeIcons.facebook,
              ),

              // LinkedIn Username
              _buildTextField(
                controller: _linkedinController,
                label: 'LinkedIn Username',
                hint: 'Your LinkedIn username',
                iconData: FontAwesomeIcons.linkedin,
              ),

              // Skills
              _buildTextField(
                controller: _skillsController,
                label: 'Skills & Interests',
                hint: 'Enter skills separated by commas',
                icon: Icons.lightbulb_outline,
                helperText: 'Example: Flutter, Dart, UI/UX Design',
              ),

              // Projects
              _buildTextField(
                controller: _projectsController,
                label: 'Previous Projects',
                hint: 'Enter projects separated by commas',
                icon: Icons.folder_outlined,
                helperText: 'Example: Campus App, Budget Tracker',
                maxLines: 2,
              ),

              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save Profile',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Center(
      child: Text(
        widget.profile.fullName.isNotEmpty
            ? widget.profile.fullName[0].toUpperCase()
            : '?',
        style: const TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryBlue,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    IconData? icon,
    IconData? iconData,
    String? helperText,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          helperText: helperText,
          prefixIcon: iconData != null
              ? Padding(
                  padding: const EdgeInsets.all(12),
                  child: FaIcon(iconData, size: 20, color: AppColors.primaryBlue),
                )
              : Icon(icon, color: AppColors.primaryBlue),
          filled: true,
          fillColor: AppColors.lightBlue.withValues(alpha: 0.5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
        ),
      ),
    );
  }
}
