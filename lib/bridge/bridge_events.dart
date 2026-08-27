/// The full JS <-> native bridge event catalog, named exactly as specified
/// in the platform repo's contract (must match
/// simpleread/src/utils/native-bridge/transport.ts and
/// simpleread/docs/app/webview-native-bridge-events.md verbatim).
library;

/// Request/response events: JS asks (via `postMessage`), native answers (via
/// `__simpleReadNativeBridgeDispatch` reusing the same message `id`).
abstract final class BridgeRequestEvents {
  /// Real handler -- uses `local_auth` for a real biometric prompt.
  static const authBiometric = 'auth.biometric';

  /// Real handler -- `firebase_messaging`. Remote push delivery is
  /// externally blocked (no real Firebase project); see README.
  static const pushRegister = 'push.register';

  /// Real handler -- `image_picker` camera capture. Untested on-device (no
  /// camera hardware on simulator/emulator); see README.
  static const cameraCapture = 'camera.capture';

  /// Real handler -- `dio` + `path_provider`, downloads a public test file
  /// (production content URL doesn't exist yet); see README.
  static const contentDownload = 'content.download';

  /// Real handler -- `share_plus`.
  static const shareSheet = 'share.sheet';

  /// Real handler -- `add_2_calendar`.
  static const calendarEvent = 'calendar.event';
}

/// Fire-and-forget events: JS -> native, no response expected.
abstract final class BridgeFireAndForgetEvents {
  /// Real handler -- stores current playback title/isPlaying.
  static const mediaPlaybackState = 'media.playback.state';
}

/// Unprompted listener events: native -> JS, no request preceded them.
abstract final class BridgeNativeToJsEvents {
  /// Real handler -- the home screen's "Pause playback" button drives this.
  static const mediaPlaybackControl = 'media.playback.control';

  /// Real handler -- the home screen's "Simulate push" button drives this
  /// (alongside a real local notification). Real remote delivery via FCM's
  /// `onMessage` would drive the same dispatch path, but is externally
  /// blocked (no real Firebase project); see README.
  static const pushReceived = 'push.received';

  /// Real handler -- `dio`'s `onReceiveProgress`, forwarded live during a
  /// `content.download` request.
  static const contentDownloadProgress = 'content.download.progress';

  /// Real handler -- `app_links`, a plain `simpleread://` custom URL scheme
  /// (no Universal Links/App Links -- those need a real domain; see README).
  static const deeplinkNavigate = 'deeplink.navigate';
}
