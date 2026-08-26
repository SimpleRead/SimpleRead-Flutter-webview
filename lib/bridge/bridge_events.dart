/// The full JS <-> native bridge event catalog, named exactly as specified
/// in the platform repo's contract (must match
/// simpleread/src/utils/native-bridge/transport.ts and
/// simpleread/docs/app/webview-native-bridge-events.md verbatim).
library;

/// Request/response events: JS asks (via `postMessage`), native answers (via
/// `__simpleReadNativeBridgeDispatch` reusing the same message `id`).
abstract final class BridgeRequestEvents {
  /// Real handler in this PoC — uses `local_auth` for a real biometric prompt.
  static const authBiometric = 'auth.biometric';

  /// Stubbed — no real APNs/FCM wiring in this PoC.
  static const pushRegister = 'push.register';

  /// Stubbed — no real camera capture in this PoC.
  static const cameraCapture = 'camera.capture';
}

/// Fire-and-forget events: JS -> native, no response expected.
abstract final class BridgeFireAndForgetEvents {
  /// Real handler in this PoC — stores current playback title/isPlaying.
  static const mediaPlaybackState = 'media.playback.state';
}

/// Unprompted listener events: native -> JS, no request preceded them.
abstract final class BridgeNativeToJsEvents {
  /// Real handler in this PoC — the home screen's "Pause playback" button
  /// drives this.
  static const mediaPlaybackControl = 'media.playback.control';

  /// Stubbed — no real push provider wired up in this PoC.
  static const pushReceived = 'push.received';
}

/// Named in the contract but explicitly NOT implemented in this PoC —
/// listed here only so the catalog is complete and greppable. See README.md
/// for why each is out of scope.
abstract final class BridgeNotYetImplementedEvents {
  static const contentDownload = 'content.download';
  static const contentDownloadProgress = 'content.download.progress';
  static const shareSheet = 'share.sheet';
  static const calendarEvent = 'calendar.event';
  static const deeplinkNavigate = 'deeplink.navigate';
}
