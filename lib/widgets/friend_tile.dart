import 'package:flutter/material.dart';
import '../models/friends.dart';
import '../services/theme_service.dart';

/// FriendTile Widget
/// Displays a single friend's information in a modern minimalist tile format.
/// Used in the Friends List Screen inside a ListView.
class FriendTile extends StatelessWidget {
  final Friend friend;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const FriendTile({
    super.key,
    required this.friend,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : AppColors.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Friend avatar with first letter of name
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  friend.name.isNotEmpty ? friend.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: isDark ? AppColors.primaryBlue : AppColors.darkText,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Friend info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    friend.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: isDark ? Colors.white : AppColors.darkText,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.school_rounded,
                        size: 14,
                        color: isDark ? Colors.white60 : AppColors.darkText.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          friend.course,
                          style: TextStyle(
                            color: isDark ? Colors.white60 : AppColors.darkText.withValues(alpha: 0.6),
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.interests_rounded,
                        size: 14,
                        color: isDark ? Colors.white60 : AppColors.darkText.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          friend.interest,
                          style: TextStyle(
                            color: isDark ? Colors.white60 : AppColors.darkText.withValues(alpha: 0.6),
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Action buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildActionButton(
                  icon: Icons.edit_rounded,
                  color: AppColors.primaryBlue,
                  onTap: onEdit,
                ),
                const SizedBox(width: 6),
                _buildActionButton(
                  icon: Icons.delete_rounded,
                  color: const Color(0xFFEF4444),
                  onTap: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 18,
          color: color,
        ),
      ),
    );
  }
}
