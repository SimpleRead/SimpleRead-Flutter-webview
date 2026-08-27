import 'package:flutter_test/flutter_test.dart';
import 'package:simpleread_flutter_shell/navigation/nav_item.dart';

void main() {
  group('NavItem.parseList', () {
    test('parses a mix of link and group items', () {
      final items = NavItem.parseList([
        {'type': 'link', 'href': '/learn', 'label': 'Biblioteca', 'icon': 'book'},
        {
          'type': 'group',
          'label': 'Gestão',
          'icon': 'school',
          'children': [
            {'type': 'link', 'href': '/admin/schools', 'label': 'Escolas', 'icon': 'school'},
          ],
        },
      ]);

      expect(items, hasLength(2));
      expect(items[0], isA<NavLinkItem>());
      expect((items[0] as NavLinkItem).href, '/learn');
      expect(items[1], isA<NavGroupItem>());
      expect((items[1] as NavGroupItem).children, hasLength(1));
    });

    test('throws BridgeParseException for a malformed item', () {
      expect(
        () => NavItem.parseList([{'type': 'link', 'href': '/x'}]),
        throwsA(isA<BridgeParseException>()),
      );
    });

    test('throws BridgeParseException when group "children" is not a list', () {
      expect(
        () => NavItem.parseList([
          {'type': 'group', 'label': 'Gestão', 'icon': 'school', 'children': 'oops'},
        ]),
        throwsA(isA<BridgeParseException>()),
      );
    });

    test('throws BridgeParseException when a group child is not a link', () {
      expect(
        () => NavItem.parseList([
          {
            'type': 'group',
            'label': 'Gestão',
            'icon': 'school',
            'children': [
              {'type': 'group', 'label': 'Nested', 'icon': 'school', 'children': []},
            ],
          },
        ]),
        throwsA(isA<BridgeParseException>()),
      );
    });

    test('throws BridgeParseException for an unknown item type', () {
      expect(
        () => NavItem.parseList([
          {'type': 'divider', 'label': 'x', 'icon': 'x'},
        ]),
        throwsA(isA<BridgeParseException>()),
      );
    });
  });
}
