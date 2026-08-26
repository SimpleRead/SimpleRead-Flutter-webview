import 'dart:convert';

/// Thrown when a raw string received over the bridge is not a valid
/// `{id, event, payload}` envelope.
class BridgeParseException implements Exception {
  final String message;
  const BridgeParseException(this.message);

  @override
  String toString() => 'BridgeParseException: $message';
}

/// The `{id, event, payload}` envelope both directions of the bridge use —
/// JS -> native via `SimpleReadNativeBridge.postMessage`, and native -> JS
/// via `window.__simpleReadNativeBridgeDispatch`.
///
/// Kept as a plain Dart class (no Flutter imports) so it — and the
/// dispatcher built on it — are unit-testable without a widget pump.
class BridgeMessage {
  final String id;
  final String event;
  final Map<String, dynamic> payload;

  const BridgeMessage({
    required this.id,
    required this.event,
    required this.payload,
  });

  /// Parses a raw JSON string from the bridge. Throws [BridgeParseException]
  /// on anything that isn't a well-formed envelope — deliberately strict:
  /// a malformed message from either side should fail loud, not silently
  /// coerce into something the dispatcher misreads.
  factory BridgeMessage.fromJsonString(String raw) {
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException catch (e) {
      throw BridgeParseException('not valid JSON: ${e.message}');
    }

    if (decoded is! Map) {
      throw BridgeParseException(
        'bridge message must be a JSON object, got ${decoded.runtimeType}',
      );
    }

    final id = decoded['id'];
    if (id is! String || id.isEmpty) {
      throw const BridgeParseException('missing or non-string "id"');
    }

    final event = decoded['event'];
    if (event is! String || event.isEmpty) {
      throw const BridgeParseException('missing or non-string "event"');
    }

    final rawPayload = decoded['payload'];
    if (rawPayload != null && rawPayload is! Map) {
      throw const BridgeParseException('"payload" must be an object when present');
    }

    return BridgeMessage(
      id: id,
      event: event,
      payload: rawPayload == null
          ? const <String, dynamic>{}
          : Map<String, dynamic>.from(rawPayload),
    );
  }

  String toJsonString() => jsonEncode({
        'id': id,
        'event': event,
        'payload': payload,
      });

  @override
  String toString() => 'BridgeMessage(id: $id, event: $event, payload: $payload)';
}
