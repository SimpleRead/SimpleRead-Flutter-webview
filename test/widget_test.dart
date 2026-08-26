// Widget test for the home screen — the plain-native surface of the
// hybrid shell. Replaces the flutter-create default counter smoke test.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:simpleread_flutter_shell/main.dart';
import 'package:simpleread_flutter_shell/screens/home_screen.dart';
import 'package:simpleread_flutter_shell/bridge/webview_bridge_registry.dart';

void main() {
  setUp(() {
    // Each test starts with no webview mounted, regardless of test order.
    WebviewBridgeRegistry.instance.value = null;
  });

  testWidgets('home screen shows title and both action buttons',
      (WidgetTester tester) async {
    await tester.pumpWidget(const SimpleReadShellApp());

    expect(find.text('SimpleRead Native Shell'), findsOneWidget);
    expect(find.byKey(const Key('open_simpleread_button')), findsOneWidget);
    expect(find.byKey(const Key('pause_playback_button')), findsOneWidget);
  });

  testWidgets(
      'pausing playback with no webview open shows the no-webview message',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    await tester.tap(find.byKey(const Key('pause_playback_button')));
    // Let the SnackBar animate in.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.text('No SimpleRead webview is open — open it first, then pause.'),
      findsOneWidget,
    );
  });

  // Deliberately not tested here: tapping "Open SimpleRead" and asserting on
  // WebviewScreen's content. Building WebviewScreen constructs a real
  // WebViewController, which requires a WebViewPlatform to be registered —
  // that only happens on a real device/simulator run (or with a full fake
  // of the (large) webview_flutter platform interface, disproportionate to
  // this PoC's scope). The bridge logic WebviewScreen wires up is covered
  // directly in test/bridge/*, independent of any real webview.
}
