import 'package:flutter_test/flutter_test.dart';
import 'package:simpleread_flutter_shell/navigation/nav_state_store.dart';

void main() {
  group('NavStateStore', () {
    test('starts with no value', () {
      final store = NavStateStore();
      expect(store.value, isNull);
    });

    test('handle() stores a well-formed payload', () {
      final store = NavStateStore();
      store.handle({
        'items': [
          {'type': 'link', 'href': '/learn', 'label': 'Biblioteca', 'icon': 'book'},
        ],
        'activeHref': '/learn',
      });

      expect(store.value?.activeHref, '/learn');
      expect(store.value?.items, hasLength(1));
    });

    test('handle() ignores a malformed payload and keeps the prior value', () {
      final store = NavStateStore();
      store.handle({
        'items': [
          {'type': 'link', 'href': '/learn', 'label': 'Biblioteca', 'icon': 'book'},
        ],
        'activeHref': '/learn',
      });
      final before = store.value;

      store.handle({'items': 'not a list'});

      expect(store.value, same(before));
    });

    test('handle() notifies listeners', () {
      final store = NavStateStore();
      var notified = false;
      store.addListener(() => notified = true);

      store.handle({'items': [], 'activeHref': null});

      expect(notified, isTrue);
    });
  });
}
