import 'package:flutter/material.dart';
import '../models/friends.dart';
import '../services/theme_service.dart';

/// Add/Edit Friend Screen
/// Provides a form to add a new friend or edit an existing friend.
/// Uses TextFormField with validation and AlertDialog for confirmation.
class AddFriendScreen extends StatefulWidget {
  // If friend is provided, we're editing; otherwise, we're adding
  final Friend? friend;

  const AddFriendScreen({super.key, this.friend});

  @override
  State<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends State<AddFriendScreen> {
  // Global key for form validation
  final _formKey = GlobalKey<FormState>();

  // Text editing controllers
  late TextEditingController _nameController;
  late TextEditingController _courseController;
  late TextEditingController _interestController;

  // Track if we're in edit mode
  bool get _isEditing => widget.friend != null;

  @override
  void initState() {
    super.initState();
    // Initialize controllers (pre-fill if editing)
    _nameController = TextEditingController(text: widget.friend?.name ?? '');
    _courseController =
        TextEditingController(text: widget.friend?.course ?? '');
    _interestController =
        TextEditingController(text: widget.friend?.interest ?? '');
  }

  @override
  void dispose() {
    // Dispose controllers to prevent memory leaks
    _nameController.dispose();
    _courseController.dispose();
    _interestController.dispose();
    super.dispose();
  }

  /// Shows an AlertDialog to confirm adding/editing a friend.
  /// If confirmed, creates a Friend object and pops back with it.
  void _saveFriend() {
    // First, validate the form
    if (_formKey.currentState!.validate()) {
      final actionText = _isEditing ? 'update' : 'add';

      // Show confirmation AlertDialog
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: Text(_isEditing ? 'Update Friend' : 'Add Friend'),
            content: Text(
              'Are you sure you want to $actionText ${_nameController.text.trim()} to your friends list?',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  // Dismiss dialog without saving
                  Navigator.pop(dialogContext);
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  // Dismiss dialog
                  Navigator.pop(dialogContext);

                  // Create friend object from form data
                  final friend = Friend(
                    name: _nameController.text.trim(),
                    course: _courseController.text.trim(),
                    interest: _interestController.text.trim(),
                  );

                  // Navigator.pop - returns friend data to FriendsScreen
                  Navigator.pop(context, friend);

                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _isEditing
                            ? 'Friend updated successfully!'
                            : 'Friend added successfully!',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: Text(_isEditing ? 'Update' : 'Add'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        title: Text(
          _isEditing ? 'Edit Friend' : 'Add Friend',
          style: TextStyle(color: isDark ? Colors.white : AppColors.darkText),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: isDark ? Colors.white : AppColors.darkText),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header icon
              Icon(
                _isEditing ? Icons.edit : Icons.person_add,
                size: 60,
                color: AppColors.primaryBlue,
              ),
              const SizedBox(height: 8),
              Text(
                _isEditing
                    ? 'Edit your friend\'s details'
                    : 'Add a new friend to your network',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.white60 : AppColors.darkText.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 24),

              // Friend Name field
              TextFormField(
                controller: _nameController,
                style: TextStyle(color: isDark ? Colors.white : AppColors.darkText),
                decoration: InputDecoration(
                  labelText: 'Friend\'s Name',
                  hintText: 'Enter friend\'s full name',
                  prefixIcon: Icon(Icons.person, color: AppColors.primaryBlue),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: isDark ? AppColors.darkCard : Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Course field
              TextFormField(
                controller: _courseController,
                style: TextStyle(color: isDark ? Colors.white : AppColors.darkText),
                decoration: InputDecoration(
                  labelText: 'Course',
                  hintText: 'e.g., BS Information Technology',
                  prefixIcon: Icon(Icons.school, color: AppColors.primaryBlue),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: isDark ? AppColors.darkCard : Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Course is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Interest field
              TextFormField(
                controller: _interestController,
                style: TextStyle(color: isDark ? Colors.white : AppColors.darkText),
                decoration: InputDecoration(
                  labelText: 'Interest',
                  hintText: 'e.g., Mobile Development',
                  prefixIcon: Icon(Icons.interests, color: AppColors.primaryBlue),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: isDark ? AppColors.darkCard : Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Interest is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Save Button
              ElevatedButton.icon(
                onPressed: _saveFriend,
                icon: Icon(_isEditing ? Icons.save : Icons.person_add, color: Colors.black),
                label: Text(
                  _isEditing ? 'Update Friend' : 'Add Friend',
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
