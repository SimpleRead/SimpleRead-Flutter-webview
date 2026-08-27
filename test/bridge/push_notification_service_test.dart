import 'package:flutter_test/flutter_test.dart';
import 'package:simpleread_flutter_shell/bridge/push_notification_service.dart';

// Only the payload -> notification content mapping is unit-tested here.
// Actually showing a notification requires a real OS notification center
// (Android/iOS), demonstrated manually via the home screen's "Simulate
// push" button -- see README.md.
void main() {
  group('PushNotificationService.buildContent', () {
    test('maps kind: chapter_ready using the payload title', () {
      final content = PushNotificationService.buildContent(
        kind: 'chapter_ready',
        payload: {'chapterId': 'c1', 'title': 'Chapter 7: The Bridge'},
      );

      expect(content.title, 'New chapter ready');
      expect(content.body, 'Chapter 7: The Bridge');
    });

    test('falls back to a generic body for chapter_ready with no title', () {
      final content = PushNotificationService.buildContent(
        kind: 'chapter_ready',
        payload: {'chapterId': 'c1'},
      );

      expect(content.title, 'New chapter ready');
      expect(content.body, 'A new chapter is ready to read.');
    });

    test('maps an unknown kind to a generic notification', () {
      final content = PushNotificationService.buildContent(
        kind: 'promo',
        payload: {},
      );

      expect(content.title, 'SimpleRead');
      expect(content.body, 'Received a "promo" push.');
    });
  });
}
