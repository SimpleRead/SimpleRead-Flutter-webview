import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simpleread_flutter_shell/bridge/push_register_handler.dart';

NotificationSettings _settings(AuthorizationStatus status) {
  return NotificationSettings(
    authorizationStatus: status,
    alert: AppleNotificationSetting.notSupported,
    announcement: AppleNotificationSetting.notSupported,
    badge: AppleNotificationSetting.notSupported,
    carPlay: AppleNotificationSetting.notSupported,
    lockScreen: AppleNotificationSetting.notSupported,
    notificationCenter: AppleNotificationSetting.notSupported,
    showPreviews: AppleShowPreviewSetting.notSupported,
    timeSensitive: AppleNotificationSetting.notSupported,
    criticalAlert: AppleNotificationSetting.notSupported,
    sound: AppleNotificationSetting.notSupported,
    providesAppNotificationSettings: AppleNotificationSetting.notSupported,
  );
}

void main() {
  group('PushRegisterHandler.handle', () {
    test('returns failed when userId is missing', () async {
      final handler = PushRegisterHandler(
        ensureFirebaseInitialized: () async {},
        requestPermission: () async => _settings(AuthorizationStatus.authorized),
        getToken: () async => 'token',
      );

      final result = await handler.handle({'role': 'student'});

      expect(result, {'success': false, 'reason': 'failed'});
    });

    test('returns failed when role is missing', () async {
      final handler = PushRegisterHandler(
        ensureFirebaseInitialized: () async {},
        requestPermission: () async => _settings(AuthorizationStatus.authorized),
        getToken: () async => 'token',
      );

      final result = await handler.handle({'userId': 'u1'});

      expect(result, {'success': false, 'reason': 'failed'});
    });

    test('returns success with the device token when permission is granted',
        () async {
      final handler = PushRegisterHandler(
        ensureFirebaseInitialized: () async {},
        requestPermission: () async => _settings(AuthorizationStatus.authorized),
        getToken: () async => 'fake-device-token',
      );

      final result = await handler.handle({'userId': 'u1', 'role': 'student'});

      expect(result, {'success': true, 'deviceToken': 'fake-device-token'});
    });

    test('treats provisional authorization as granted', () async {
      final handler = PushRegisterHandler(
        ensureFirebaseInitialized: () async {},
        requestPermission: () async => _settings(AuthorizationStatus.provisional),
        getToken: () async => 'fake-device-token',
      );

      final result = await handler.handle({'userId': 'u1', 'role': 'student'});

      expect(result, {'success': true, 'deviceToken': 'fake-device-token'});
    });

    test('returns permission_denied when the user denies the permission',
        () async {
      final handler = PushRegisterHandler(
        ensureFirebaseInitialized: () async {},
        requestPermission: () async => _settings(AuthorizationStatus.denied),
        getToken: () async => 'fake-device-token',
      );

      final result = await handler.handle({'userId': 'u1', 'role': 'student'});

      expect(result, {'success': false, 'reason': 'permission_denied'});
    });

    test('returns failed when getToken() returns null', () async {
      final handler = PushRegisterHandler(
        ensureFirebaseInitialized: () async {},
        requestPermission: () async => _settings(AuthorizationStatus.authorized),
        getToken: () async => null,
      );

      final result = await handler.handle({'userId': 'u1', 'role': 'student'});

      expect(result, {'success': false, 'reason': 'failed'});
    });

    test(
        'returns failed when Firebase initialization throws (the real, '
        'expected outcome with no Firebase project configured)', () async {
      final handler = PushRegisterHandler(
        ensureFirebaseInitialized: () async =>
            throw Exception('no google-services.json / GoogleService-Info.plist'),
        requestPermission: () async => _settings(AuthorizationStatus.authorized),
        getToken: () async => 'unused',
      );

      final result = await handler.handle({'userId': 'u1', 'role': 'student'});

      expect(result, {'success': false, 'reason': 'failed'});
    });
  });
}
