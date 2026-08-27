import 'package:flutter_test/flutter_test.dart';
import 'package:simpleread_flutter_shell/bridge/bridge_dispatcher.dart';
import 'package:simpleread_flutter_shell/bridge/bridge_events.dart';
import 'package:simpleread_flutter_shell/navigation/nav_state_store.dart';
import 'package:simpleread_flutter_shell/screens/webview_screen.dart';

// WebviewScreen itself is not pumped here: its initState() constructs a
// real WebViewController, which needs a registered platform implementation
// this repo's test suite doesn't set up anywhere (no
// webview_flutter_platform_interface fake in dev_dependencies, no existing
// test/screens/ precedent). These tests cover only the two units Task 8
// actually adds and that are reachable without pumping the widget: the
// bridge event name constant, and the static store AppShell (Task 7) reads
// from outside the widget tree -- the same gap left uncovered for
// mediaPlaybackState's own registration line today.
void main() {
  group('navigation.state wiring surface', () {
    test('BridgeFireAndForgetEvents.navigationState is "navigation.state"', () {
      expect(BridgeFireAndForgetEvents.navigationState, 'navigation.state');
    });

    test('WebviewScreen exposes a static NavStateStore singleton', () {
      expect(WebviewScreen.navStateStore, isA<NavStateStore>());
      expect(
        identical(WebviewScreen.navStateStore, WebviewScreen.navStateStore),
        isTrue,
      );
    });
  });

  group('dispatcher wiring (same idiom as bridge_dispatcher_test.dart)', () {
    test('a dispatcher wired like WebviewScreen routes navigation.state '
        'into WebviewScreen.navStateStore', () async {
      final dispatcher = BridgeDispatcher();
      dispatcher.registerFireAndForgetHandler(
        BridgeFireAndForgetEvents.navigationState,
        WebviewScreen.navStateStore.handle,
      );

      final result = await dispatcher.handleIncoming(
        '{"id":"evt-1","event":"navigation.state",'
        '"payload":{"items":[],"activeHref":"/learn"}}',
      );

      expect(result, isNull);
      expect(WebviewScreen.navStateStore.value?.activeHref, '/learn');
    });
  });
}
