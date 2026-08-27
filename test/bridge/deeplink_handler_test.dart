import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:simpleread_flutter_shell/bridge/deeplink_handler.dart';

void main() {
  group('DeeplinkHandler.parsePath', () {
    test('parses path from a well-formed simpleread:// link', () {
      final path = DeeplinkHandler.parsePath(
        Uri.parse('simpleread://open?path=/learn/x'),
      );
      expect(path, '/learn/x');
    });

    test('returns null for a different scheme', () {
      final path = DeeplinkHandler.parsePath(
        Uri.parse('https://open?path=/learn/x'),
      );
      expect(path, isNull);
    });

    test('returns null when the path query parameter is missing', () {
      final path = DeeplinkHandler.parsePath(Uri.parse('simpleread://open'));
      expect(path, isNull);
    });

    test('returns null when the path query parameter is empty', () {
      final path = DeeplinkHandler.parsePath(
        Uri.parse('simpleread://open?path='),
      );
      expect(path, isNull);
    });
  });

  group('DeeplinkHandler.start — stream links', () {
    test('dispatches deeplink.navigate for a matching link on the stream',
        () async {
      final controller = StreamController<Uri>();
      final dispatched = <String>[];
      final handler = DeeplinkHandler(
        linkStream: controller.stream,
        dispatch: (path) async {
          dispatched.add(path);
          return true;
        },
        initialLink: () async => null,
      );

      handler.start();
      controller.add(Uri.parse('simpleread://open?path=/learn/x'));
      await Future<void>.delayed(Duration.zero);

      expect(dispatched, ['/learn/x']);

      await controller.close();
      handler.dispose();
    });

    test('does not dispatch for a link that fails to parse', () async {
      final controller = StreamController<Uri>();
      final dispatched = <String>[];
      final handler = DeeplinkHandler(
        linkStream: controller.stream,
        dispatch: (path) async {
          dispatched.add(path);
          return true;
        },
        initialLink: () async => null,
      );

      handler.start();
      controller.add(Uri.parse('https://example.com/not-our-scheme'));
      await Future<void>.delayed(Duration.zero);

      expect(dispatched, isEmpty);

      await controller.close();
      handler.dispose();
    });

    test('dispose() stops further dispatches', () async {
      final controller = StreamController<Uri>();
      final dispatched = <String>[];
      final handler = DeeplinkHandler(
        linkStream: controller.stream,
        dispatch: (path) async {
          dispatched.add(path);
          return true;
        },
        initialLink: () async => null,
      );

      handler.start();
      handler.dispose();
      controller.add(Uri.parse('simpleread://open?path=/learn/x'));
      await Future<void>.delayed(Duration.zero);

      expect(dispatched, isEmpty);

      await controller.close();
    });
  });

  group('DeeplinkHandler.start — cold-start initial link', () {
    // Regression test for a real bug: uriLinkStream only reports links that
    // arrive while the app is already running. A link the process was
    // cold-started with is never replayed on it -- only getInitialLink()
    // sees it. Missing this meant `simpleread://...` silently did nothing
    // on a cold launch.
    test('dispatches the link the app was cold-started with', () async {
      final dispatched = <String>[];
      final handler = DeeplinkHandler(
        linkStream: const Stream<Uri>.empty(),
        dispatch: (path) async {
          dispatched.add(path);
          return true;
        },
        initialLink: () async => Uri.parse('simpleread://open?path=/learn/cold'),
      );

      handler.start();
      await Future<void>.delayed(Duration.zero);

      expect(dispatched, ['/learn/cold']);

      handler.dispose();
    });

    test('does nothing when there is no initial link', () async {
      final dispatched = <String>[];
      final handler = DeeplinkHandler(
        linkStream: const Stream<Uri>.empty(),
        dispatch: (path) async {
          dispatched.add(path);
          return true;
        },
        initialLink: () async => null,
      );

      handler.start();
      await Future<void>.delayed(Duration.zero);

      expect(dispatched, isEmpty);

      handler.dispose();
    });
  });

  group('DeeplinkHandler — retry when the webview is not mounted yet', () {
    // Regression test for a second real bug: WebviewBridgeRegistry's send
    // methods return false (not an error) when no controller is registered
    // yet -- exactly the state at cold start, before WebviewScreen has
    // mounted. The old code discarded that boolean and dropped the link.
    test('retries dispatch until it succeeds', () async {
      var attempts = 0;
      final dispatched = <String>[];
      final handler = DeeplinkHandler(
        linkStream: const Stream<Uri>.empty(),
        dispatch: (path) async {
          attempts++;
          if (attempts < 3) return false;
          dispatched.add(path);
          return true;
        },
        initialLink: () async => Uri.parse('simpleread://open?path=/learn/retry'),
        retryDelay: Duration.zero,
      );

      handler.start();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(attempts, 3);
      expect(dispatched, ['/learn/retry']);

      handler.dispose();
    });

    // Regression test for a third real bug: WKWebView's runJavaScript
    // throws (FWFEvaluateJavaScriptError), not returns false, when called
    // before the page is ready to evaluate script -- observed live on a
    // fresh WebviewScreen mount. An uncaught throw here would abort the
    // whole retry loop on the very first attempt instead of just failing
    // that attempt.
    test('treats a thrown dispatch error as a failed attempt and retries',
        () async {
      var attempts = 0;
      final dispatched = <String>[];
      final handler = DeeplinkHandler(
        linkStream: const Stream<Uri>.empty(),
        dispatch: (path) async {
          attempts++;
          if (attempts < 2) {
            throw Exception('FWFEvaluateJavaScriptError');
          }
          dispatched.add(path);
          return true;
        },
        initialLink: () async => Uri.parse('simpleread://open?path=/learn/throwy'),
        retryDelay: Duration.zero,
      );

      handler.start();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(attempts, 2);
      expect(dispatched, ['/learn/throwy']);

      handler.dispose();
    });

    test('gives up after the retry budget is exhausted', () async {
      var attempts = 0;
      final handler = DeeplinkHandler(
        linkStream: const Stream<Uri>.empty(),
        dispatch: (path) async {
          attempts++;
          return false;
        },
        initialLink: () async => Uri.parse('simpleread://open?path=/learn/never'),
        retryDelay: Duration.zero,
      );

      handler.start();
      // 1 initial attempt + up to 10 retries = 11 total.
      for (var i = 0; i < 12; i++) {
        await Future<void>.delayed(Duration.zero);
      }

      expect(attempts, 11);

      handler.dispose();
    });
  });
}
