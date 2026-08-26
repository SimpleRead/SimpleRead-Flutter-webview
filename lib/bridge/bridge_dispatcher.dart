import 'bridge_message.dart';

/// Handles a JS request event and returns the response payload that gets
/// wrapped back into a [BridgeMessage] with the same `id`/`event`.
typedef BridgeRequestHandler = Future<Map<String, dynamic>> Function(
  Map<String, dynamic> payload,
);

/// Handles a fire-and-forget JS event. No response is sent.
typedef BridgeFireAndForgetHandler = void Function(Map<String, dynamic> payload);

/// Routes incoming `{id, event, payload}` envelopes (as raw JSON strings,
/// exactly what a `JavaScriptChannel.onMessageReceived` callback hands you)
/// to registered handlers by event name.
///
/// Pure Dart, no Flutter/webview_flutter imports — the webview screen wires
/// this to the actual `JavaScriptChannel` and `WebViewController`, but the
/// routing logic itself is tested in isolation.
class BridgeDispatcher {
  final Map<String, BridgeRequestHandler> _requestHandlers = {};
  final Map<String, BridgeFireAndForgetHandler> _fireAndForgetHandlers = {};

  void registerRequestHandler(String event, BridgeRequestHandler handler) {
    _requestHandlers[event] = handler;
  }

  void registerFireAndForgetHandler(String event, BridgeFireAndForgetHandler handler) {
    _fireAndForgetHandlers[event] = handler;
  }

  /// Processes one raw JSON string received from JS.
  ///
  /// Returns the raw JSON string to hand back to
  /// `window.__simpleReadNativeBridgeDispatch` for a registered
  /// request/response event, or `null` when the event is fire-and-forget or
  /// has no registered handler (stubbed/unknown events fall silently into
  /// this last case by design — see README for which events are stubs).
  ///
  /// Propagates [BridgeParseException] for a malformed envelope; the caller
  /// (the webview screen) decides how to surface that.
  Future<String?> handleIncoming(String rawJson) async {
    final message = BridgeMessage.fromJsonString(rawJson);

    final requestHandler = _requestHandlers[message.event];
    if (requestHandler != null) {
      final responsePayload = await requestHandler(message.payload);
      final response = BridgeMessage(
        id: message.id,
        event: message.event,
        payload: responsePayload,
      );
      return response.toJsonString();
    }

    final fireAndForgetHandler = _fireAndForgetHandlers[message.event];
    if (fireAndForgetHandler != null) {
      fireAndForgetHandler(message.payload);
      return null;
    }

    return null;
  }
}
