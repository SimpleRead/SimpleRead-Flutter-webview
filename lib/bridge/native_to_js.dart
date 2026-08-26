import 'dart:convert';

import 'bridge_message.dart';

/// Builds the native -> JS half of the bridge: turns a
/// `{id, event, payload}` envelope into the exact JS snippet a
/// `WebViewController.runJavaScript` call should execute to invoke
/// `window.__simpleReadNativeBridgeDispatch` on the page.
///
/// Pure Dart (no webview_flutter import) so the string-building is
/// unit-testable without a WebView.
abstract final class NativeToJs {
  /// Builds the envelope for an unprompted listener event (e.g.
  /// `media.playback.control`) — native generates its own `id` since no JS
  /// request preceded it.
  static BridgeMessage buildEvent({
    required String event,
    required Map<String, dynamic> payload,
    String Function()? idGenerator,
  }) {
    final id = (idGenerator ?? _defaultIdGenerator)();
    return BridgeMessage(id: id, event: event, payload: payload);
  }

  /// The exact JS to hand to `WebViewController.runJavaScript`.
  ///
  /// The bridge message's own JSON is re-encoded as a JS string literal
  /// (via `jsonEncode` on the string itself) so it survives as a single
  /// argument to `__simpleReadNativeBridgeDispatch` regardless of quotes
  /// inside the payload.
  static String dispatchScript(BridgeMessage message) {
    return dispatchScriptForRawJson(message.toJsonString());
  }

  /// Same as [dispatchScript] but for a raw JSON string already in hand
  /// (e.g. a response envelope built by [BridgeDispatcher.handleIncoming]),
  /// so callers don't have to re-parse it into a [BridgeMessage] first.
  static String dispatchScriptForRawJson(String rawJson) {
    final jsStringLiteral = jsonEncode(rawJson);
    return 'window.__simpleReadNativeBridgeDispatch($jsStringLiteral);';
  }

  static String _defaultIdGenerator() =>
      'native-${DateTime.now().microsecondsSinceEpoch}';
}
