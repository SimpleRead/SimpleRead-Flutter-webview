// On-device verification for the two things that need a real device/
// simulator and can't be covered by test/bridge/*'s injected-fake unit
// tests: push.register's real (uncaught) Firebase error with no project
// configured, and push.received's real local notification display.
//
// NOT part of `flutter test`'s default run (that only scans test/, not
// this directory) -- run explicitly against a device/simulator:
//
//   flutter test integration_test/app_test.dart -d <device-id>
//
// See README.md for the exact output this produced.

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:simpleread_flutter_shell/bridge/push_register_handler.dart';
import 'package:simpleread_flutter_shell/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'push.register: real Firebase.initializeApp() error with no project '
      'configured (no google-services.json / GoogleService-Info.plist)',
      (tester) async {
    // Calls the real SDK directly (not through PushRegisterHandler's
    // try/catch, which maps any failure to {success: false, reason:
    // 'failed'}) so the real, unmapped exception text can be printed and
    // captured verbatim for README.md, rather than the handler's already-
    // caught-and-generalized result.
    try {
      await Firebase.initializeApp();
      debugPrint('REAL_FIREBASE_INIT_RESULT: unexpectedly succeeded');
    } catch (e) {
      debugPrint('REAL_FIREBASE_INIT_ERROR: ${e.runtimeType}: $e');
    }

    // Also exercises the actual handler used in production, confirming it
    // maps that failure to the contract's shape rather than throwing.
    final result = await PushRegisterHandler().handle({
      'userId': 'verify-user',
      'role': 'student',
    });
    debugPrint('PUSH_REGISTER_HANDLER_RESULT: $result');
    expect(result['success'], false);
  });

  testWidgets(
      'push.received: "Simulate push" shows a real local notification',
      (tester) async {
    app.main();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('simulate_push_button')));
    await tester.pumpAndSettle();
    // Hold the frame so an external screenshot (see README.md) can capture
    // the notification banner before the test process exits.
    await tester.pump(const Duration(seconds: 5));
  });
}
