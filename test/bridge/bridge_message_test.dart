import 'package:flutter_test/flutter_test.dart';
import 'package:simpleread_flutter_shell/bridge/bridge_message.dart';

void main() {
  group('BridgeMessage.fromJsonString', () {
    test('parses a well-formed envelope', () {
      final message = BridgeMessage.fromJsonString(
        '{"id":"abc-1","event":"auth.biometric","payload":{"userId":"u1"}}',
      );

      expect(message.id, 'abc-1');
      expect(message.event, 'auth.biometric');
      expect(message.payload, {'userId': 'u1'});
    });

    test('defaults payload to an empty map when absent', () {
      final message = BridgeMessage.fromJsonString(
        '{"id":"abc-2","event":"media.playback.control"}',
      );

      expect(message.payload, <String, dynamic>{});
    });

    test('defaults payload to an empty map when explicitly null', () {
      final message = BridgeMessage.fromJsonString(
        '{"id":"abc-3","event":"media.playback.control","payload":null}',
      );

      expect(message.payload, <String, dynamic>{});
    });

    test('throws BridgeParseException on invalid JSON', () {
      expect(
        () => BridgeMessage.fromJsonString('not json at all'),
        throwsA(isA<BridgeParseException>()),
      );
    });

    test('throws BridgeParseException when the JSON is not an object', () {
      expect(
        () => BridgeMessage.fromJsonString('[1,2,3]'),
        throwsA(isA<BridgeParseException>()),
      );
    });

    test('throws BridgeParseException when "id" is missing', () {
      expect(
        () => BridgeMessage.fromJsonString('{"event":"auth.biometric"}'),
        throwsA(isA<BridgeParseException>()),
      );
    });

    test('throws BridgeParseException when "id" is not a string', () {
      expect(
        () => BridgeMessage.fromJsonString(
          '{"id":42,"event":"auth.biometric"}',
        ),
        throwsA(isA<BridgeParseException>()),
      );
    });

    test('throws BridgeParseException when "event" is missing', () {
      expect(
        () => BridgeMessage.fromJsonString('{"id":"abc-4"}'),
        throwsA(isA<BridgeParseException>()),
      );
    });

    test('throws BridgeParseException when "payload" is not an object', () {
      expect(
        () => BridgeMessage.fromJsonString(
          '{"id":"abc-5","event":"auth.biometric","payload":"nope"}',
        ),
        throwsA(isA<BridgeParseException>()),
      );
    });
  });

  group('BridgeMessage.toJsonString', () {
    test('round-trips id, event, and payload', () {
      const message = BridgeMessage(
        id: 'abc-6',
        event: 'media.playback.state',
        payload: {'title': 'Chapter 1', 'isPlaying': true},
      );

      final roundTripped = BridgeMessage.fromJsonString(message.toJsonString());

      expect(roundTripped.id, message.id);
      expect(roundTripped.event, message.event);
      expect(roundTripped.payload, message.payload);
    });
  });
}
