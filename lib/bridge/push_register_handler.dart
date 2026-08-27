import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Real handler for `push.register` -- Firebase Cloud Messaging (FCM).
///
/// Each Firebase call is injected as a plain function rather than depending
/// on the live `FirebaseMessaging` singleton directly, so the
/// success/denied/error branches below are unit-testable without a real
/// Firebase project or a device -- same shape as [BiometricAuthHandler]'s
/// `LocalAuthentication` injection, adapted for a plugin that (unlike
/// `local_auth`) doesn't expose a single swappable `Platform.instance` its
/// public API reads through on every call.
///
/// The real defaults below WILL fail without a real Firebase project's
/// native config file -- `google-services.json` (Android) /
/// `GoogleService-Info.plist` (iOS) -- which does not exist in this PoC.
/// See README.md for the exact missing file/path and the exact error
/// observed running this for real.
class PushRegisterHandler {
  PushRegisterHandler({
    Future<void> Function()? ensureFirebaseInitialized,
    Future<NotificationSettings> Function()? requestPermission,
    Future<String?> Function()? getToken,
  })  : _ensureFirebaseInitialized =
            ensureFirebaseInitialized ?? _defaultEnsureFirebaseInitialized,
        _requestPermission =
            requestPermission ?? _defaultRequestPermission,
        _getToken = getToken ?? _defaultGetToken;

  final Future<void> Function() _ensureFirebaseInitialized;
  final Future<NotificationSettings> Function() _requestPermission;
  final Future<String?> Function() _getToken;

  /// Matches the `push.register` response shape from the contract:
  /// `{success, deviceToken?, reason?}`.
  Future<Map<String, dynamic>> handle(Map<String, dynamic> payload) async {
    final userId = payload['userId'];
    final role = payload['role'];
    if (userId is! String || userId.isEmpty || role is! String || role.isEmpty) {
      return const {'success': false, 'reason': 'failed'};
    }

    try {
      await _ensureFirebaseInitialized();

      final settings = await _requestPermission();
      final granted = settings.authorizationStatus ==
              AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
      if (!granted) {
        return const {'success': false, 'reason': 'permission_denied'};
      }

      final token = await _getToken();
      if (token == null) {
        return const {'success': false, 'reason': 'failed'};
      }
      return {'success': true, 'deviceToken': token};
    } on Object {
      // Real, expected failure mode in this PoC: no Firebase project config
      // file exists, so Firebase.initializeApp()/getToken() throw. Caught
      // here rather than propagated, mapped to the contract's generic
      // failure reason -- the exact error text is captured for real in
      // README.md, not fabricated.
      return const {'success': false, 'reason': 'failed'};
    }
  }

  static Future<void> _defaultEnsureFirebaseInitialized() async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  }

  static Future<NotificationSettings> _defaultRequestPermission() {
    return FirebaseMessaging.instance.requestPermission();
  }

  static Future<String?> _defaultGetToken() {
    return FirebaseMessaging.instance.getToken();
  }
}
