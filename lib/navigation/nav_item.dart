import '../bridge/bridge_message.dart';

export '../bridge/bridge_message.dart' show BridgeParseException;

/// Parsed form of a single entry in the `navigation.state` bridge event's
/// nav list -- either a leaf link or a group that expands into links.
///
/// Sealed (not just abstract) so a `switch` over subtypes is
/// exhaustiveness-checked at compile time as later tasks (the tab bar
/// widget) branch on it.
sealed class NavItem {
  const NavItem({required this.label, required this.icon});

  final String label;
  final String icon;

  /// Parses the raw `List` from the event payload. Strict like
  /// [BridgeMessage.fromJsonString]: any malformed item throws
  /// [BridgeParseException] rather than being skipped or coerced.
  static List<NavItem> parseList(List<dynamic> raw) =>
      raw.map(_parseOne).toList();

  static NavItem _parseOne(dynamic raw) {
    if (raw is! Map) {
      throw BridgeParseException('nav item is not an object: $raw');
    }

    switch (raw['type']) {
      case 'link':
        return NavLinkItem(
          href: _requireString(raw, 'href'),
          label: _requireString(raw, 'label'),
          icon: _requireString(raw, 'icon'),
        );
      case 'group':
        final rawChildren = raw['children'];
        if (rawChildren is! List) {
          throw BridgeParseException('group item missing "children": $raw');
        }
        return NavGroupItem(
          label: _requireString(raw, 'label'),
          icon: _requireString(raw, 'icon'),
          children: rawChildren.map((c) {
            final child = _parseOne(c);
            if (child is! NavLinkItem) {
              throw BridgeParseException('group child is not a link: $c');
            }
            return child;
          }).toList(),
        );
      default:
        throw BridgeParseException('unknown nav item type: ${raw['type']}');
    }
  }

  static String _requireString(Map raw, String key) {
    final value = raw[key];
    if (value is! String || value.isEmpty) {
      throw BridgeParseException('nav item missing "$key": $raw');
    }
    return value;
  }
}

/// A leaf nav entry that navigates to [href] when tapped.
class NavLinkItem extends NavItem {
  const NavLinkItem({
    required this.href,
    required super.label,
    required super.icon,
  });

  final String href;
}

/// A nav entry that expands into a list of [children] links rather than
/// navigating directly.
class NavGroupItem extends NavItem {
  const NavGroupItem({
    required super.label,
    required super.icon,
    required this.children,
  });

  final List<NavLinkItem> children;
}
