import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/supabase_service.dart';
import '../services/theme_service.dart';
import '../models/repository.dart';

/// Add/Edit Project Screen - Bumble-inspired project creation
/// Allows users to create projects with GitHub integration, README, and images
class AddProjectScreen extends StatefulWidget {
  final Repository? existingProject;

  const AddProjectScreen({super.key, this.existingProject});

  @override
  State<AddProjectScreen> createState() => _AddProjectScreenState();
}

class _AddProjectScreenState extends State<AddProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _readmeController = TextEditingController();
  final _githubUrlController = TextEditingController();
  final _demoUrlController = TextEditingController();
  
  String _selectedLanguage = 'Dart';
  String _selectedStatus = 'in_progress';
  bool _isPublic = true;
  bool _isLoading = false;
  List<String> _selectedTechnologies = [];
  List<XFile> _selectedImages = [];
  List<String> _existingImageUrls = [];

  final List<String> _languages = [
    'Dart', 'Python', 'JavaScript', 'TypeScript', 'Java', 'Kotlin',
    'Swift', 'C++', 'C#', 'Go', 'Rust', 'PHP', 'Ruby', 'Other'
  ];

  final List<String> _statuses = [
    'idea', 'in_progress', 'completed', 'archived'
  ];

  final Map<String, String> _statusLabels = {
    'idea': '💡 Idea',
    'in_progress': '🚧 In Progress',
    'completed': '✅ Completed',
    'archived': '📦 Archived',
  };

  final List<String> _commonTechnologies = [
    'Flutter', 'React', 'React Native', 'Node.js', 'Firebase', 
    'Supabase', 'PostgreSQL', 'MongoDB', 'Docker', 'AWS',
    'REST API', 'GraphQL', 'TensorFlow', 'Machine Learning',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingProject != null) {
      _loadExistingProject();
    }
  }

  void _loadExistingProject() {
    final project = widget.existingProject!;
    _nameController.text = project.name;
    _descriptionController.text = project.description;
    _readmeController.text = project.longDescription;
    _githubUrlController.text = project.githubUrl ?? '';
    _demoUrlController.text = project.demoUrl ?? '';
    _selectedLanguage = project.language;
    _selectedStatus = project.status;
    _isPublic = project.isPublic;
    _selectedTechnologies = List.from(project.technologies);
    if (project.thumbnailUrl != null) {
      _existingImageUrls = [project.thumbnailUrl!];
    }
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images.take(5 - _selectedImages.length));
      });
    }
  }

  Future<void> _saveProject() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Upload images if any
      String? thumbnailUrl;
      if (_selectedImages.isNotEmpty) {
        // In production, you would upload to Supabase Storage
        // For now, we'll skip the upload
        thumbnailUrl = _existingImageUrls.isNotEmpty ? _existingImageUrls.first : null;
      }

      final projectData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'long_description': _readmeController.text.trim(),
        'language': _selectedLanguage,
        'status': _selectedStatus,
        'is_public': _isPublic,
        'technologies': _selectedTechnologies,
        'github_url': _githubUrlController.text.trim().isEmpty 
            ? null 
            : _githubUrlController.text.trim(),
        'demo_url': _demoUrlController.text.trim().isEmpty 
            ? null 
            : _demoUrlController.text.trim(),
        'thumbnail_url': thumbnailUrl,
      };

      if (widget.existingProject != null) {
        await SupabaseService.updateProject(widget.existingProject!.id!, projectData);
      } else {
        await SupabaseService.createProject(
          name: projectData['name'] as String,
          description: projectData['description'] as String,
          language: projectData['language'] as String,
          isPublic: projectData['is_public'] as bool,
          topics: _selectedTechnologies,
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingProject != null 
                ? 'Project updated successfully!' 
                : 'Project created successfully!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _readmeController.dispose();
    _githubUrlController.dispose();
    _demoUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.grey,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.existingProject != null ? 'Edit Project' : 'New Project',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _saveProject,
              child: Text(
                'Save',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryBlue,
                  fontSize: 16,
                ),
              ),
            ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Project Images Section
            _buildSection(
              title: 'Project Images',
              icon: Icons.image_rounded,
              child: Column(
                children: [
                  // Image Preview
                  if (_selectedImages.isNotEmpty || _existingImageUrls.isNotEmpty)
                    Container(
                      height: 180,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedImages.length + _existingImageUrls.length,
                        itemBuilder: (context, index) {
                          final isNewImage = index < _selectedImages.length;
                          
                          return Container(
                            width: 280,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark ? AppColors.darkCardBorder : AppColors.cardBorder,
                              ),
                            ),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child: isNewImage
                                      ? Image.file(
                                          File(_selectedImages[index].path),
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: double.infinity,
                                        )
                                      : Image.network(
                                          _existingImageUrls[index - _selectedImages.length],
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: double.infinity,
                                        ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        if (isNewImage) {
                                          _selectedImages.removeAt(index);
                                        } else {
                                          _existingImageUrls.removeAt(index - _selectedImages.length);
                                        }
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  
                  // Add Images Button
                  GestureDetector(
                    onTap: _pickImages,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : AppColors.grey,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? AppColors.darkCardBorder : AppColors.cardBorder,
                          style: BorderStyle.solid,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.add_photo_alternate_rounded,
                              size: 48,
                              color: AppColors.primaryBlue,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Add project screenshots',
                              style: TextStyle(
                                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Up to 5 images',
                              style: TextStyle(
                                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Basic Info Section
            _buildSection(
              title: 'Basic Information',
              icon: Icons.info_outline_rounded,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Project Name *',
                      hintText: 'Enter your project name',
                      prefixIcon: const Icon(Icons.folder_rounded),
                      filled: true,
                      fillColor: isDark ? AppColors.darkCard : Colors.white,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a project name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Short Description *',
                      hintText: 'Briefly describe your project',
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 50),
                        child: Icon(Icons.description_rounded),
                      ),
                      filled: true,
                      fillColor: isDark ? AppColors.darkCard : Colors.white,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a description';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedLanguage,
                          decoration: InputDecoration(
                            labelText: 'Language',
                            prefixIcon: const Icon(Icons.code_rounded),
                            filled: true,
                            fillColor: isDark ? AppColors.darkCard : Colors.white,
                          ),
                          items: _languages.map((lang) {
                            return DropdownMenuItem(
                              value: lang,
                              child: Text(lang),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedLanguage = value!);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedStatus,
                          decoration: InputDecoration(
                            labelText: 'Status',
                            prefixIcon: const Icon(Icons.flag_rounded),
                            filled: true,
                            fillColor: isDark ? AppColors.darkCard : Colors.white,
                          ),
                          items: _statuses.map((status) {
                            return DropdownMenuItem(
                              value: status,
                              child: Text(_statusLabels[status]!),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedStatus = value!);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Technologies Section
            _buildSection(
              title: 'Technologies Used',
              icon: Icons.build_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _commonTechnologies.map((tech) {
                      final isSelected = _selectedTechnologies.contains(tech);
                      return FilterChip(
                        label: Text(tech),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedTechnologies.add(tech);
                            } else {
                              _selectedTechnologies.remove(tech);
                            }
                          });
                        },
                        selectedColor: AppColors.primaryBlue.withOpacity(0.3),
                        checkmarkColor: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        labelStyle: TextStyle(
                          color: isSelected 
                              ? (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)
                              : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // GitHub Section
            _buildSection(
              title: 'GitHub Repository',
              icon: Icons.code_rounded,
              iconColor: const Color(0xFF181717),
              child: Column(
                children: [
                  TextFormField(
                    controller: _githubUrlController,
                    decoration: InputDecoration(
                      labelText: 'GitHub URL',
                      hintText: 'https://github.com/username/repo',
                      prefixIcon: const Icon(Icons.link_rounded),
                      filled: true,
                      fillColor: isDark ? AppColors.darkCard : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _demoUrlController,
                    decoration: InputDecoration(
                      labelText: 'Demo/Live URL',
                      hintText: 'https://your-demo-url.com',
                      prefixIcon: const Icon(Icons.open_in_new_rounded),
                      filled: true,
                      fillColor: isDark ? AppColors.darkCard : Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // README Section
            _buildSection(
              title: 'README / Documentation',
              icon: Icons.article_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Write a detailed description of your project. Supports Markdown formatting.',
                    style: TextStyle(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _readmeController,
                    maxLines: 10,
                    decoration: InputDecoration(
                      hintText: '''# Project Name

## Description
What does your project do?

## Features
- Feature 1
- Feature 2

## Installation
How to install and run your project

## Screenshots
Add screenshots reference here

## Tech Stack
List the technologies used

## Contributors
- Your Name''',
                      filled: true,
                      fillColor: isDark ? AppColors.darkCard : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Visibility Section
            _buildSection(
              title: 'Visibility',
              icon: Icons.visibility_rounded,
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Public Project',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  _isPublic 
                      ? 'Everyone can see this project'
                      : 'Only you can see this project',
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
                value: _isPublic,
                onChanged: (value) => setState(() => _isPublic = value),
                activeColor: AppColors.primaryBlue,
              ),
            ),

            const SizedBox(height: 40),

            // Save Button
            ElevatedButton(
              onPressed: _isLoading ? null : _saveProject,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      widget.existingProject != null ? 'Update Project' : 'Create Project',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    Color? iconColor,
    required Widget child,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (iconColor ?? AppColors.primaryBlue).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? AppColors.primaryBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
