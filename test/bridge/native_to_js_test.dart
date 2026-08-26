import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:simpleread_flutter_shell/bridge/bridge_message.dart';
import 'package:simpleread_flutter_shell/bridge/native_to_js.dart';

void main() {
  group('NativeToJs.buildEvent', () {
    test('generates a non-empty id when none is supplied', () {
      final message = NativeToJs.buildEvent(
        event: 'media.playback.control',
        payload: {'action': 'pause'},
      );

      expect(message.id, isNotEmpty);
      expect(message.event, 'media.playback.control');
      expect(message.payload, {'action': 'pause'});
    });

    test('uses the supplied id generator when given', () {
      final message = NativeToJs.buildEvent(
        event: 'media.playback.control',
        payload: {'action': 'next'},
        idGenerator: () => 'fixed-id',
      );

      expect(message.id, 'fixed-id');
    });
  });

  group('NativeToJs.dispatchScript', () {
    test('wraps the message in a call to '
        'window.__simpleReadNativeBridgeDispatch', () {
      const message = BridgeMessage(
        id: 'fixed-id',
        event: 'media.playback.control',
        payload: {'action': 'pause'},
      );

      final script = NativeToJs.dispatchScript(message);

      expect(
        script,
        startsWith('window.__simpleReadNativeBridgeDispatch('),
      );
      expect(script, endsWith(');'));

      // The argument is a JS string literal containing the message's JSON —
      // decode it twice to recover the original envelope.
      final argument = script.substring(
        'window.__simpleReadNativeBridgeDispatch('.length,
        script.length - 2,
      );
      final rawJson = jsonDecode(argument) as String;
      final decoded = jsonDecode(rawJson) as Map<String, dynamic>;

      expect(decoded['id'], 'fixed-id');
      expect(decoded['event'], 'media.playback.control');
      expect(decoded['payload'], {'action': 'pause'});
    });

    test('survives quotes and newlines inside the payload', () {
      const message = BridgeMessage(
        id: 'fixed-id',
        event: 'media.playback.state',
        payload: {'title': 'A "quoted" title\nwith a newline'},
      );

      final script = NativeToJs.dispatchScript(message);
      final argument = script.substring(
        'window.__simpleReadNativeBridgeDispatch('.length,
        script.length - 2,
      );

      final rawJson = jsonDecode(argument) as String;
      final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
      expect(
        (decoded['payload'] as Map)['title'],
        'A "quoted" title\nwith a newline',
      );
    });
  });
}
