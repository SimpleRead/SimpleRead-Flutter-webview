import 'dart:async';

import 'package:app_links/app_links.dart';

import 'webview_bridge_registry.dart';

/// Wires a `simpleread://` custom URL scheme to the `deeplink.navigate`
/// native -> JS listener event.
///
/// Deliberately does NOT attempt Universal Links / App Links -- those need
/// a real domain hosting `apple-app-site-association` / `assetlinks.json`,
/// which this PoC doesn't have (see README.md). A plain custom scheme needs
/// no external account: only the native manifest entries this repo already
/// carries (`AndroidManifest.xml`'s intent-filter, `Info.plist`'s
/// `CFBundleURLTypes`).
///
/// The link stream and the dispatch call are both injected so the
/// scheme/path parsing is unit-testable without `app_links`' platform
/// channel or a real webview.
class DeeplinkHandler {
  DeeplinkHandler({
    Stream<Uri>? linkStream,
    void Function(String path)? dispatch,
  })  : _linkStream = linkStream ?? AppLinks().uriLinkStream,
        _dispatch = dispatch ?? WebviewBridgeRegistry.instance.sendDeeplinkNavigate;

  final Stream<Uri> _linkStream;
  final void Function(String path) _dispatch;
  StreamSubscription<Uri>? _subscription;

  /// Parses a `simpleread://open?path=/learn/x` URI into the `path` string
  /// the contract's `deeplink.navigate` payload carries. Returns `null` for
  /// anything that isn't a well-formed `simpleread://` link with a `path`
  /// query parameter -- the wrong scheme, or a missing/empty `path`.
  static String? parsePath(Uri uri) {
    if (uri.scheme != 'simpleread') return null;
    final path = uri.queryParameters['path'];
    if (path == null || path.isEmpty) return null;
    return path;
  }

  /// Starts listening. Call once, for the app's lifetime (see main.dart) --
  /// deep links must be caught regardless of which screen is on top.
  void start() {
    _subscription = _linkStream.listen((uri) {
      final path = parsePath(uri);
      if (path != null) {
        _dispatch(path);
      }
    });
  }

  void dispose() {
    _subscription?.cancel();
  }
}
