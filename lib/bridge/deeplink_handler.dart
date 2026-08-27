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
    Future<bool> Function(String path)? dispatch,
    Future<Uri?> Function()? initialLink,
    Duration? retryDelay,
  })  : _linkStream = linkStream ?? AppLinks().uriLinkStream,
        _dispatch = dispatch ?? WebviewBridgeRegistry.instance.sendDeeplinkNavigate,
        _initialLink = initialLink ?? AppLinks().getInitialLink,
        _retryDelay = retryDelay ?? const Duration(milliseconds: 200);

  final Stream<Uri> _linkStream;
  final Future<bool> Function(String path) _dispatch;
  final Future<Uri?> Function() _initialLink;
  final Duration _retryDelay;
  StreamSubscription<Uri>? _subscription;

  /// The cold-start link resolves (and this listener starts) before
  /// WebviewScreen has necessarily mounted and registered its controller
  /// with WebviewBridgeRegistry -- dispatch would silently no-op the first
  /// try. Retries a bounded number of times rather than dropping the link.
  ///
  /// A registered controller isn't sufficient either: WKWebView throws
  /// FWFEvaluateJavaScriptError (a real, reproduced bug) if runJavaScript is
  /// called before the page itself is ready to evaluate script, which
  /// happens for the first retry or two right after WebviewScreen mounts.
  /// That's a thrown exception, not a `false` return -- must be caught here
  /// too, or it aborts the retry loop instead of just failing this attempt.
  Future<void> _dispatchWithRetry(String path, {int attemptsLeft = 10}) async {
    var delivered = false;
    try {
      delivered = await _dispatch(path);
    } catch (_) {
      delivered = false;
    }
    if (delivered || attemptsLeft <= 0) return;
    await Future<void>.delayed(_retryDelay);
    await _dispatchWithRetry(path, attemptsLeft: attemptsLeft - 1);
  }

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
  ///
  /// Also checks the link the app was cold-started with, if any.
  /// `uriLinkStream` only reports links that arrive while the app is
  /// already running; a link that launched the process in the first place
  /// is never replayed on that stream -- `AppLinks().getInitialLink()` is
  /// the only way to see it. Missing this was a real bug: cold-starting the
  /// app via `simpleread://...` silently did nothing.
  void start() {
    _subscription = _linkStream.listen((uri) {
      final path = parsePath(uri);
      if (path != null) {
        _dispatchWithRetry(path);
      }
    });
    _handleInitialLink();
  }

  Future<void> _handleInitialLink() async {
    final uri = await _initialLink();
    if (uri == null) return;
    final path = parsePath(uri);
    if (path != null) {
      await _dispatchWithRetry(path);
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}
