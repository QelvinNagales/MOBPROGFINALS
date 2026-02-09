import 'package:flutter/material.dart';
import '../models/activity.dart';
import '../services/theme_service.dart';

/// ActivityTile Widget
/// Displays an activity item in the activity feed with modern minimalist design.
class ActivityTile extends StatelessWidget {
  final Activity activity;
  final VoidCallback? onTap;

  const ActivityTile({
    super.key,
    required this.activity,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Activity icon
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _getActivityColor().withValues(alpha: isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  activity.activityIcon,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Activity details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isDark ? Colors.white : AppColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    activity.description,
                    style: TextStyle(
                      color: isDark ? Colors.white60 : AppColors.darkText.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    activity.timeAgo,
                    style: TextStyle(
                      color: isDark ? Colors.white38 : AppColors.darkText.withValues(alpha: 0.4),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getActivityColor() {
    switch (activity.type) {
      case ActivityType.newConnection:
        return const Color(0xFF10B981);
      case ActivityType.projectCreated:
        return AppColors.primaryBlue;
      case ActivityType.projectUpdated:
        return const Color(0xFF06B6D4);
      case ActivityType.projectStarred:
        return AppColors.primaryBlue;
      case ActivityType.projectForked:
        return const Color(0xFF8B5CF6);
      case ActivityType.profileUpdated:
        return const Color(0xFF14B8A6);
      case ActivityType.skillAdded:
        return const Color(0xFFF97316);
      case ActivityType.comment:
        return const Color(0xFF6366F1);
      case ActivityType.collaborationStarted:
        return const Color(0xFF7C3AED);
      case ActivityType.achievementEarned:
        return AppColors.primaryBlue;
    }
  }
}
