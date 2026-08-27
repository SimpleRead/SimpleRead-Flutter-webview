import 'package:flutter/foundation.dart';

import 'nav_item.dart';

/// Holds the last `navigation.state` fire-and-forget event received from JS:
/// `{items: NavItem[], activeHref: string | null}`.
///
/// A `ValueNotifier` rather than a full state-management library — mirrors
/// [PlaybackStateStore]: the webview screen just needs to reflect the latest
/// state it was told about.
class NavStateStore extends ValueNotifier<NavState?> {
  NavStateStore() : super(null);

  void handle(Map<String, dynamic> payload) {
    final rawItems = payload['items'];
    if (rawItems is! List) return;
    try {
      final items = NavItem.parseList(rawItems);
      final activeHref = payload['activeHref'];
      value = NavState(
        items: items,
        activeHref: activeHref is String ? activeHref : null,
      );
    } on BridgeParseException {
      // A malformed item inside an otherwise-list payload — drop silently,
      // same convention as [BridgeDispatcher]/[PlaybackStateStore].
    }
  }
}

@immutable
class NavState {
  final List<NavItem> items;
  final String? activeHref;

  const NavState({required this.items, required this.activeHref});
}
