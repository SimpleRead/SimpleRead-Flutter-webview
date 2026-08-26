import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'bridge_events.dart';
import 'native_to_js.dart';

/// Lets the native (non-webview) home screen reach the live webview's JS
/// runtime to prove native -> JS actually works, without either screen
/// holding a direct reference to the other.
///
/// The webview screen registers its controller here on mount and clears it
/// on dispose; the home screen's "Pause playback" button reads it here.
class WebviewBridgeRegistry extends ValueNotifier<WebViewController?> {
  WebviewBridgeRegistry._() : super(null);

  static final WebviewBridgeRegistry instance = WebviewBridgeRegistry._();

  /// Sends a `media.playback.control` listener event into the page, e.g.
  /// `action: 'pause'`. No-op (returns false) if no webview is currently
  /// mounted.
  Future<bool> sendPlaybackControl(String action) async {
    final controller = value;
    if (controller == null) {
      return false;
    }

    final message = NativeToJs.buildEvent(
      event: BridgeNativeToJsEvents.mediaPlaybackControl,
      payload: {'action': action},
    );
    await controller.runJavaScript(NativeToJs.dispatchScript(message));
    return true;
  }
}
