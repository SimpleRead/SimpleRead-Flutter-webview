import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// The title/body a `push.received` payload maps to -- a real local
/// notification is built from this, but it's returned as plain data too so
/// the mapping itself is unit-testable without an OS notification center.
class PushNotificationContent {
  final String title;
  final String body;
  const PushNotificationContent({required this.title, required this.body});
}

/// Drives real local notification display for `push.received` events
/// (`{kind, payload}`).
///
/// This is deliberately independent of [PushRegisterHandler]/FCM: it's
/// triggered by the home screen's "Simulate push" button with a synthetic
/// payload (no external push provider needed), proving the
/// local-notification half of push works end to end without a Firebase
/// project. A real FCM message arriving via `FirebaseMessaging.onMessage`
/// would call the same [showForPushReceived] -- that wiring is externally
/// blocked the same way [PushRegisterHandler] is; see README.md.
class PushNotificationService {
  PushNotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  Future<void> ensureInitialized() async {
    if (_initialized) return;
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _plugin.initialize(settings: settings);
    _initialized = true;
  }

  /// Builds notification content for a `push.received` payload. Pure
  /// mapping logic, no plugin call -- unit-testable on its own.
  static PushNotificationContent buildContent({
    required String kind,
    required Map<String, dynamic> payload,
  }) {
    switch (kind) {
      case 'chapter_ready':
        final title = payload['title'];
        return PushNotificationContent(
          title: 'New chapter ready',
          body: title is String ? title : 'A new chapter is ready to read.',
        );
      default:
        return PushNotificationContent(
          title: 'SimpleRead',
          body: 'Received a "$kind" push.',
        );
    }
  }

  /// Shows a real local notification for a `push.received` payload and
  /// returns the content it was built from.
  Future<PushNotificationContent> showForPushReceived({
    required String kind,
    required Map<String, dynamic> payload,
  }) async {
    await ensureInitialized();
    final content = buildContent(kind: kind, payload: payload);
    await _plugin.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
      title: content.title,
      body: content.body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'simpleread_push_received',
          'SimpleRead push notifications',
          channelDescription: 'Notifications simulated by the "Simulate push" '
              'dev button, and (once a real Firebase project exists) real '
              'FCM pushes.',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
    return content;
  }
}
