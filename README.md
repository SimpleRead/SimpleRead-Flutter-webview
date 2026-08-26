# SimpleRead — Flutter Hybrid Shell PoC

This is **one of two parallel proof-of-concept implementations** built to let
engineers compare "hybrid native shell + embedded WebView" mobile strategies
hands-on (app size, DX, who maintains the webview component, build
friction). This one is Flutter. A sibling agent built the same pattern in
React Native, in a separate sibling directory — this repo does not depend on
it and was built independently.

**This is not a production app.** It is a PoC proving one pattern: a real
native app shell with a WebView screen that loads the existing SimpleRead
web app UNCHANGED, plus native screens/integrations around it, communicating
over a JS↔native bridge.

## What's here

- **Home screen** (`lib/screens/home_screen.dart`) — plain native Flutter,
  no webview. Has an "Open SimpleRead" button (pushes the webview screen)
  and a "Pause playback" button (demonstrates native → JS push, see below).
  This is the app's "more than a repackaged website" surface, relevant to
  Apple/Google app-store minimum-functionality review.
- **Webview screen** (`lib/screens/webview_screen.dart`) — `webview_flutter`
  (the official, pub.dev **verified-publisher `flutter.dev`** package —
  confirmed on its pub.dev page before adding it, not assumed) loading
  `simpleReadUrl` from `lib/config.dart`.
- **Bridge layer** (`lib/bridge/`) — the JS↔native contract, implemented as
  plain Dart classes with no Flutter/webview imports, so the routing and
  (de)serialization logic is unit-testable without a widget pump or a real
  WebView:
  - `bridge_message.dart` — the `{id, event, payload}` envelope both
    directions use, with strict parsing (`BridgeParseException` on anything
    malformed rather than silently coercing it).
  - `bridge_events.dart` — the full event catalog as named constants.
  - `bridge_dispatcher.dart` — routes an incoming raw JSON string to a
    registered handler by event name; returns the JSON to send back to JS
    for request/response events, or `null` for fire-and-forget/unhandled
    events.
  - `native_to_js.dart` — builds the `runJavaScript` snippet for a native →
    JS listener event (re-encodes the envelope as a JS string literal so it
    survives quotes/newlines in the payload).
  - `biometric_handler.dart` — **real** `auth.biometric` handler, see below.
  - `stub_handlers.dart` — **stub** `push.register` / `camera.capture`
    handlers, see below.
  - `playback_state_store.dart` — **real** `media.playback.state` handler
    (a `ValueNotifier` shown in the webview screen's overlay).
  - `webview_bridge_registry.dart` — lets the native home screen reach the
    live webview's JS runtime (see "native → JS" below) without the two
    screens holding a direct reference to each other.

## Bridge contract

Matches the contract given in the task brief verbatim — this repo does not
read or depend on `~/sl/simpleread` (out of scope; the ground rules for this
PoC forbid touching that repo), so it was not diffed against
`src/utils/native-bridge/transport.ts` directly. If that file changes, this
bridge layer needs re-checking against it.

- **JS → native**: the page calls
  `window.SimpleReadNativeBridge.postMessage(rawJsonString)` where JSON is
  `{id, event, payload}`. Wired via a `JavaScriptChannel` named exactly
  `SimpleReadNativeBridge` (`webview_screen.dart`).
- **native → JS**: the shell calls
  `window.__simpleReadNativeBridgeDispatch(rawJsonString)`, same shape,
  either as a response (same `id` as the request) or an unprompted listener
  event (native-generated `id`).

### Real vs. stubbed, per event

| Event | Status | Notes |
|---|---|---|
| `auth.biometric` | **Real** | `BiometricAuthHandler` (local_auth) — a real Face ID/Touch ID/fingerprint prompt. Maps `LocalAuthExceptionCode` to the contract's `not_enrolled` / `user_cancelled` / `failed` reasons. |
| `media.playback.state` | **Real** | Fire-and-forget JS→native; stored in `PlaybackStateStore`, shown in the webview screen's bottom overlay. |
| `media.playback.control` | **Real** | Native→JS; the home screen's "Pause playback" button sends `{action: 'pause'}` to the currently-open webview via `WebviewBridgeRegistry` + `runJavaScript`. If no webview is open, the button shows a SnackBar saying so instead of silently doing nothing. |
| `push.register` | Stub | `TODO` in `stub_handlers.dart`. No real APNs/FCM project — out of scope per the task brief. Always returns `{success: false, reason: 'not_implemented_stub'}`. |
| `camera.capture` | Stub | `TODO` in `stub_handlers.dart`. No real camera wiring — out of scope per the task brief. Same stub response shape. |
| `push.received` | **Not implemented** | Native→JS listener; no push provider to trigger it from in this PoC. |
| `content.download` / `content.download.progress` | **Not implemented** | Not built in this PoC. |
| `share.sheet` | **Not implemented** | Not built in this PoC. |
| `calendar.event` | **Not implemented** | Not built in this PoC. |
| `deeplink.navigate` | **Not implemented** | Not built in this PoC. |

The "not implemented" events aren't silently dropped by accident — the
dispatcher's `handleIncoming` returns `null` for any event with no
registered handler, by design, which is exactly how these are (not) handled.

## Before this is useful for anything

`lib/config.dart`'s `simpleReadUrl` is a **placeholder constant**:

```dart
const String simpleReadUrl = 'https://STAGING_URL_PLACEHOLDER.example';
```

This does not point at a real SimpleRead deployment (none was available
while building this PoC). Point it at a real staging URL before running
this against anything real.

## Running it

```bash
flutter pub get
flutter run              # picks whatever device/simulator is connected
```

Toolchain used to build this repo: Flutter 3.44.7 (stable), Dart 3.12.2.

## Toolchain gaps: what was expected vs. what actually happened

The task brief flagged two likely blockers going in. Both were tried for
real; **neither actually blocked a build** in this environment — reported
here exactly as observed, not assumed:

- **CocoaPods (`pod`) not installed.** `pod --version` → command not found.
  Expected this to break iOS native module linking (`pod install`). But
  `flutter build ios --simulator` never invokes CocoaPods at all here:
  this Flutter/Xcode combination (feature flag
  `enable-swift-package-manager`, confirmed via `flutter doctor -v`) links
  `local_auth_darwin` and `webview_flutter_wkwebview` through Swift Package
  Manager instead — no `Podfile` is generated, and
  `ios/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage`
  contains the resolved plugin package instead. The build succeeded (see
  below). CocoaPods absence would still block a plugin that *requires* a
  Podfile (one without SPM support), but neither plugin used here does.

- **Android SDK Platform 35.0.1 installed; Flutter's doctor wants 36.**
  `flutter doctor` reports this as a failing check (not a warning —
  `✗ Flutter requires Android SDK 36 and the Android BuildTools 28.0.3`).
  Despite that, `flutter build apk --debug` succeeded: Gradle's own SDK
  manager silently installed Android SDK Platform 36, Build-Tools 36.0.0,
  NDK 28.2.13676358, and CMake 3.22.1 on demand during the build (licenses
  were already accepted globally, so no interactive prompt was needed). So
  in this environment the doctor failure did not translate into a build
  failure — but that's contingent on licenses being pre-accepted; a fresh
  machine without accepted licenses would likely stop here.

## Verification (real output, not paraphrased)

### `flutter analyze`

```
Analyzing simpleread-flutter-shell...
No issues found! (ran in 0.7s)
```

### `flutter test`

```
00:00 +33: All tests passed!
```

33 tests, 0 failures, across:
- `test/bridge/bridge_message_test.dart` — envelope parsing/serialization,
  including malformed-input cases.
- `test/bridge/bridge_dispatcher_test.dart` — request/response routing,
  fire-and-forget routing, unhandled-event routing, malformed-input
  propagation.
- `test/bridge/native_to_js_test.dart` — the `runJavaScript` snippet
  builder, including payloads with quotes/newlines.
- `test/bridge/biometric_handler_test.dart` — every branch of
  `BiometricAuthHandler` (missing/invalid `userId`, device unsupported,
  success, user-cancel-without-error, and each mapped
  `LocalAuthExceptionCode`), using a fake `LocalAuthPlatform` substituted via
  its settable `.instance` — no device/simulator needed.
- `test/bridge/playback_state_store_test.dart` — the `media.playback.state`
  store.
- `test/widget_test.dart` — home screen renders title and both buttons;
  tapping "Pause playback" with no webview open shows the correct message.
  Deliberately does **not** widget-test pushing into the real
  `WebviewScreen` — building it constructs a real `WebViewController`, which
  needs a `WebViewPlatform` registered, and that only happens on a real
  device/simulator run (faking the full webview platform interface for one
  test was judged disproportionate to this PoC's scope). See the comment in
  the file.

### `flutter build apk --debug`

Succeeded: `build/app/outputs/flutter-apk/app-debug.apk` (141.6 MB debug
build; unstripped, includes Flutter's debug JIT snapshot — a release build
would be much smaller).

### `flutter build ios --simulator`

Succeeded: `build/ios/iphonesimulator/Runner.app`, containing
`local_auth_darwin` and `webview_flutter_wkwebview` linked via Swift Package
Manager (see toolchain-gaps section above) — no CocoaPods involved.

Neither build was run on an actual device/simulator (no interactive
run/launch was attempted) — both are `flutter build`, i.e. compiled but not
executed.
