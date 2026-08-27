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

  group('DeeplinkHandler.start', () {
    test('dispatches deeplink.navigate for a matching link on the stream',
        () async {
      final controller = StreamController<Uri>();
      final dispatched = <String>[];
      final handler = DeeplinkHandler(
        linkStream: controller.stream,
        dispatch: dispatched.add,
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
        dispatch: dispatched.add,
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
        dispatch: dispatched.add,
      );

      handler.start();
      handler.dispose();
      controller.add(Uri.parse('simpleread://open?path=/learn/x'));
      await Future<void>.delayed(Duration.zero);

      expect(dispatched, isEmpty);

      await controller.close();
    });
  });
}
