import 'package:flutter_test/flutter_test.dart';
import 'package:simpleread_flutter_shell/bridge/playback_state_store.dart';

void main() {
  group('PlaybackStateStore', () {
    test('starts with no value', () {
      final store = PlaybackStateStore();
      expect(store.value, isNull);
    });

    test('handle() stores a well-formed payload', () {
      final store = PlaybackStateStore();

      store.handle({'title': 'Chapter 1', 'isPlaying': true});

      expect(store.value?.title, 'Chapter 1');
      expect(store.value?.isPlaying, true);
    });

    test('handle() notifies listeners', () {
      final store = PlaybackStateStore();
      var notifications = 0;
      store.addListener(() => notifications++);

      store.handle({'title': 'Chapter 2', 'isPlaying': false});

      expect(notifications, 1);
    });

    test('handle() ignores a malformed payload and keeps the prior value',
        () {
      final store = PlaybackStateStore();
      store.handle({'title': 'Chapter 1', 'isPlaying': true});

      store.handle({'title': 'Chapter 2'}); // missing isPlaying

      expect(store.value?.title, 'Chapter 1');
    });
  });
}
