import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/post.dart';
import '../theme/app_theme.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, this.radius = 21});

  final double radius;

  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: radius,
    backgroundColor: AppColors.tint,
    child: Icon(
      Icons.person_outline_rounded,
      color: AppColors.primary,
      size: radius + 3,
    ),
  );
}

String formatPostTime(DateTime time) {
  final difference = DateTime.now().difference(time);
  if (difference.inMinutes < 1) return 'Just now';
  if (difference.inHours < 1) return '${difference.inMinutes}m ago';
  if (difference.inDays < 1) return '${difference.inHours}h ago';
  return DateFormat('MMM d, h:mm a').format(time);
}

extension VisibilityPresentation on PostVisibility {
  String get label => switch (this) {
    PostVisibility.public => 'Public',
    PostVisibility.friends => 'Friends',
    PostVisibility.onlyMe => 'Only me',
  };

  IconData get icon => switch (this) {
    PostVisibility.public => Icons.public_rounded,
    PostVisibility.friends => Icons.people_outline_rounded,
    PostVisibility.onlyMe => Icons.lock_outline_rounded,
  };
}
