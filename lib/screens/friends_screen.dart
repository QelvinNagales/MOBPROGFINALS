import 'package:flutter/material.dart';
import '../models/friends.dart';
import '../widgets/friend_tile.dart';
import '../services/theme_service.dart';
import 'add_friend_screen.dart';

/// Friends List Screen
/// Displays all friends in a modern minimalist ListView using FriendTile widgets.
class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  // In-memory friends list using setState
  final List<Friend> _friends = [
    Friend(
      name: 'Maria Santos',
      course: 'BS Computer Science',
      interest: 'Web Development',
    ),
    Friend(
      name: 'Carlos Reyes',
      course: 'BS Information Technology',
      interest: 'Game Development',
    ),
    Friend(
      name: 'Ana Garcia',
      course: 'BS Computer Science',
      interest: 'Data Science',
    ),
  ];

  /// Navigates to AddFriendScreen to add a new friend.
  void _navigateToAddFriend() async {
    final newFriend = await Navigator.push<Friend>(
      context,
      MaterialPageRoute(
        builder: (context) => const AddFriendScreen(),
      ),
    );

    if (newFriend != null) {
      setState(() {
        _friends.add(newFriend);
      });
    }
  }

  /// Navigates to AddFriendScreen to edit an existing friend.
  void _navigateToEditFriend(int index) async {
    final updatedFriend = await Navigator.push<Friend>(
      context,
      MaterialPageRoute(
        builder: (context) => AddFriendScreen(friend: _friends[index]),
      ),
    );

    if (updatedFriend != null) {
      setState(() {
        _friends[index] = updatedFriend;
      });
    }
  }

  /// Shows a dialog to confirm friend deletion.
  void _deleteFriend(int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkCard : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Remove Friend',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.darkText,
            ),
          ),
          content: Text(
            'Are you sure you want to remove ${_friends[index].name} from your friends list?',
            style: TextStyle(color: isDark ? Colors.white70 : AppColors.darkText.withValues(alpha: 0.6)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancel',
                style: TextStyle(color: isDark ? Colors.white60 : AppColors.darkText.withValues(alpha: 0.6)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                setState(() {
                  _friends.removeAt(index);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Friend removed'),
                    backgroundColor: const Color(0xFFEF4444),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        elevation: 0,
        title: Text(
          'Friends',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppColors.darkText,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: isDark ? Colors.white : AppColors.darkText),
      ),
      body: _friends.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.people_outline_rounded,
                      size: 56,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No friends yet',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the + button to add a friend',
                    style: TextStyle(
                      color: isDark ? Colors.white60 : AppColors.darkText.withValues(alpha: 0.6),
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _friends.length,
              itemBuilder: (context, index) {
                return FriendTile(
                  friend: _friends[index],
                  onEdit: () => _navigateToEditFriend(index),
                  onDelete: () => _deleteFriend(index),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddFriend,
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 4,
        child: const Icon(Icons.person_add_rounded),
      ),
    );
  }
}
