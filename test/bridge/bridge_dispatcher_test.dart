import 'package:flutter_test/flutter_test.dart';
import 'package:simpleread_flutter_shell/bridge/bridge_dispatcher.dart';
import 'package:simpleread_flutter_shell/bridge/bridge_message.dart';

void main() {
  group('BridgeDispatcher.handleIncoming', () {
    test('routes a request event to its handler and wraps the response '
        'with the same id and event', () async {
      final dispatcher = BridgeDispatcher();
      dispatcher.registerRequestHandler('auth.biometric', (payload) async {
        expect(payload, {'userId': 'u1'});
        return {'success': true};
      });

      final responseJson = await dispatcher.handleIncoming(
        '{"id":"req-1","event":"auth.biometric","payload":{"userId":"u1"}}',
      );

      expect(responseJson, isNotNull);
      final response = BridgeMessage.fromJsonString(responseJson!);
      expect(response.id, 'req-1');
      expect(response.event, 'auth.biometric');
      expect(response.payload, {'success': true});
    });

    test('routes a fire-and-forget event to its handler and returns null',
        () async {
      final dispatcher = BridgeDispatcher();
      Map<String, dynamic>? received;
      dispatcher.registerFireAndForgetHandler('media.playback.state', (payload) {
        received = payload;
      });

      final result = await dispatcher.handleIncoming(
        '{"id":"evt-1","event":"media.playback.state",'
        '"payload":{"title":"Chapter 1","isPlaying":true}}',
      );

      expect(result, isNull);
      expect(received, {'title': 'Chapter 1', 'isPlaying': true});
    });

    test('returns null for an event with no registered handler on this '
        'dispatcher instance', () async {
      final dispatcher = BridgeDispatcher();

      final result = await dispatcher.handleIncoming(
        '{"id":"evt-2","event":"some.unregistered.event","payload":{}}',
      );

      expect(result, isNull);
    });

    test('propagates BridgeParseException for a malformed envelope',
        () async {
      final dispatcher = BridgeDispatcher();

      expect(
        () => dispatcher.handleIncoming('not json'),
        throwsA(isA<BridgeParseException>()),
      );
    });

    test('two different request handlers do not cross-talk', () async {
      final dispatcher = BridgeDispatcher();
      dispatcher.registerRequestHandler(
        'auth.biometric',
        (payload) async => {'success': true},
      );
      dispatcher.registerRequestHandler(
        'push.register',
        (payload) async => {'success': false, 'reason': 'not_implemented_stub'},
      );

      final biometricResponse = await dispatcher.handleIncoming(
        '{"id":"a","event":"auth.biometric","payload":{}}',
      );
      final pushResponse = await dispatcher.handleIncoming(
        '{"id":"b","event":"push.register","payload":{}}',
      );

      expect(
        BridgeMessage.fromJsonString(biometricResponse!).payload,
        {'success': true},
      );
      expect(
        BridgeMessage.fromJsonString(pushResponse!).payload,
        {'success': false, 'reason': 'not_implemented_stub'},
      );
    });
  });
}
