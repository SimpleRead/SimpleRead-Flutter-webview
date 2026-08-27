import 'package:flutter/material.dart';

import '../bridge/webview_bridge_registry.dart';
import 'nav_icons.dart';
import 'nav_item.dart';
import 'nav_state_store.dart';

/// Above this many top-level items, the tail collapses into a "Mais" tab
/// (see [_fixedTabCount]) -- see the design doc's "Tab bar behavior".
const int _maxFixedTabs = 5;

/// How many real items stay as fixed tabs once a "Mais" tab is needed.
const int _fixedTabCount = 4;

/// The shell around [body]: renders it bare until the first
/// `navigation.state` event arrives (same as before this feature existed),
/// then wraps it in a [Scaffold] with a native [BottomNavigationBar] built
/// from [store]'s current [NavState].
///
/// `body` is left untyped ([WebviewScreen] is wired in by a later task) so
/// this widget stays testable without a real webview.
class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.store,
    required this.body,
    void Function(String href)? onNavigate,
  }) : _onNavigate = onNavigate ?? _defaultNavigate;

  final NavStateStore store;
  final Widget body;
  final void Function(String href) _onNavigate;

  /// Navigates the existing shared [WebViewController] directly -- no JS
  /// round-trip, per the design doc.
  static void _defaultNavigate(String href) {
    WebviewBridgeRegistry.instance.value?.loadRequest(Uri.parse(href));
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<NavState?>(
      valueListenable: store,
      builder: (context, state, _) {
        if (state == null || state.items.isEmpty) {
          return body;
        }
        return _buildScaffold(context, state);
      },
    );
  }

  Widget _buildScaffold(BuildContext context, NavState state) {
    final items = state.items;
    final hasOverflow = items.length > _maxFixedTabs;
    final tabs = hasOverflow ? items.take(_fixedTabCount).toList() : items;
    final overflowItems = hasOverflow
        ? items.skip(_fixedTabCount).toList()
        : const <NavItem>[];

    return Scaffold(
      body: body,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _activeIndex(
          tabs,
          overflowItems,
          hasOverflow,
          state.activeHref,
        ),
        items: [
          for (final item in tabs)
            BottomNavigationBarItem(
              icon: Icon(iconForKey(item.icon)),
              label: item.label,
            ),
          if (hasOverflow)
            const BottomNavigationBarItem(
              icon: Icon(Icons.more_horiz),
              label: 'Mais',
            ),
        ],
        onTap: (index) =>
            _handleTap(context, tabs, overflowItems, hasOverflow, index),
      ),
    );
  }

  void _handleTap(
    BuildContext context,
    List<NavItem> tabs,
    List<NavItem> overflowItems,
    bool hasOverflow,
    int index,
  ) {
    if (hasOverflow && index == tabs.length) {
      _showItemsSheet(context, overflowItems);
      return;
    }
    _activate(context, tabs[index]);
  }

  void _activate(BuildContext context, NavItem item) {
    switch (item) {
      case NavLinkItem(href: final href):
        _onNavigate(href);
      case NavGroupItem(children: final children):
        _showItemsSheet(context, children);
    }
  }

  void _showItemsSheet(BuildContext context, List<NavItem> items) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final item in items)
              ListTile(
                leading: Icon(iconForKey(item.icon)),
                title: Text(item.label),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _activate(context, item);
                },
              ),
          ],
        ),
      ),
    );
  }

  /// The tab index [activeHref] selects: an exact match on a fixed tab's
  /// `href`, a match nested inside a fixed group tab's children, a match
  /// nested inside an overflowed item (which highlights "Mais"), or `0` if
  /// nothing matches.
  int _activeIndex(
    List<NavItem> tabs,
    List<NavItem> overflowItems,
    bool hasOverflow,
    String? activeHref,
  ) {
    if (activeHref == null) return 0;
    for (var i = 0; i < tabs.length; i++) {
      if (_matches(tabs[i], activeHref)) return i;
    }
    if (hasOverflow &&
        overflowItems.any((item) => _matches(item, activeHref))) {
      return tabs.length;
    }
    return 0;
  }

  bool _matches(NavItem item, String activeHref) {
    return switch (item) {
      NavLinkItem(href: final href) => href == activeHref,
      NavGroupItem(children: final children) => children.any(
        (child) => child.href == activeHref,
      ),
    };
  }
}
