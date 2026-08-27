import 'package:flutter/material.dart';

/// Maps a `navigation.state` icon key (from the platform's
/// `routes.tsx` `getIcon(iconType: string)`) to a Material icon.
IconData iconForKey(String key) {
  switch (key) {
    case 'school':
      return Icons.school_outlined;
    case 'home':
      return Icons.home_outlined;
    case 'teacher':
      return Icons.person_outline;
    case 'classroom':
      return Icons.groups_outlined;
    case 'exam':
      return Icons.description_outlined;
    case 'book':
      return Icons.menu_book_outlined;
    case 'coordinator':
      return Icons.badge_outlined;
    case 'pipeline':
      return Icons.sync_alt_outlined;
    case 'audit':
      return Icons.verified_outlined;
    case 'stats':
      return Icons.bar_chart_outlined;
    case 'currency':
      return Icons.payments_outlined;
    default:
      return Icons.circle_outlined;
  }
}
