import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'bridge_events.dart';
import 'native_to_js.dart';

/// Lets native (non-webview) code reach the live webview's JS runtime to
/// prove native -> JS actually works, without either side holding a direct
/// reference to the other.
///
/// The webview screen registers its controller here on mount and clears it
/// on dispose; native code (the home screen's buttons, a download in
/// progress, an incoming push, a deep link) reads it here.
class WebviewBridgeRegistry extends ValueNotifier<WebViewController?> {
  WebviewBridgeRegistry._() : super(null);

  static final WebviewBridgeRegistry instance = WebviewBridgeRegistry._();

  /// Sends a `media.playback.control` listener event into the page, e.g.
  /// `action: 'pause'`. No-op (returns false) if no webview is currently
  /// mounted.
  Future<bool> sendPlaybackControl(String action) {
    return _send(
      event: BridgeNativeToJsEvents.mediaPlaybackControl,
      payload: {'action': action},
    );
  }

  /// Sends a `push.received` listener event into the page: `{kind, payload}`.
  /// No-op (returns false) if no webview is currently mounted.
  Future<bool> sendPushReceived(String kind, Map<String, dynamic> payload) {
    return _send(
      event: BridgeNativeToJsEvents.pushReceived,
      payload: {'kind': kind, 'payload': payload},
    );
  }

  /// Sends a `content.download.progress` listener event into the page:
  /// `{contentId, percent}`. No-op (returns false) if no webview is
  /// currently mounted -- a download in progress with no webview open just
  /// has nowhere to report progress to, which is not an error.
  Future<bool> sendContentDownloadProgress(String contentId, int percent) {
    return _send(
      event: BridgeNativeToJsEvents.contentDownloadProgress,
      payload: {'contentId': contentId, 'percent': percent},
    );
  }

  /// Sends a `deeplink.navigate` listener event into the page: `{path}`.
  /// No-op (returns false) if no webview is currently mounted.
  Future<bool> sendDeeplinkNavigate(String path) {
    return _send(
      event: BridgeNativeToJsEvents.deeplinkNavigate,
      payload: {'path': path},
    );
  }

  Future<bool> _send({
    required String event,
    required Map<String, dynamic> payload,
  }) async {
    final controller = value;
    if (controller == null) {
      return false;
    }

    final message = NativeToJs.buildEvent(event: event, payload: payload);
    await controller.runJavaScript(NativeToJs.dispatchScript(message));
    return true;
  }
}
