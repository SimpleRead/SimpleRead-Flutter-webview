import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simpleread_flutter_shell/navigation/nav_icons.dart';

void main() {
  test('maps known icon keys', () {
    expect(iconForKey('book'), Icons.menu_book_outlined);
    expect(iconForKey('school'), Icons.school_outlined);
    expect(iconForKey('stats'), Icons.bar_chart_outlined);
  });

  test('maps every real icon key from routes.tsx getIcon()', () {
    expect(iconForKey('school'), Icons.school_outlined);
    expect(iconForKey('home'), Icons.home_outlined);
    expect(iconForKey('teacher'), Icons.person_outline);
    expect(iconForKey('classroom'), Icons.groups_outlined);
    expect(iconForKey('exam'), Icons.description_outlined);
    expect(iconForKey('book'), Icons.menu_book_outlined);
    expect(iconForKey('coordinator'), Icons.badge_outlined);
    expect(iconForKey('pipeline'), Icons.sync_alt_outlined);
    expect(iconForKey('audit'), Icons.verified_outlined);
    expect(iconForKey('stats'), Icons.bar_chart_outlined);
    expect(iconForKey('currency'), Icons.payments_outlined);
  });

  test('falls back to a default icon for an unknown key', () {
    expect(iconForKey('something-new'), Icons.circle_outlined);
  });
}
