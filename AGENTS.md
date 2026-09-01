# AGENTS.md

Context file for AI agents (Hermes included) working against this repo. Full detail lives
in `README.md` — this file is the compressed map, not a replacement for it.

## What this is

PoC, not production. A native Flutter shell whose only screen is a WebView loading the
existing SimpleRead web app **unchanged**, plus native device integrations wired through a
JS↔native bridge. Sibling PoC in React Native exists elsewhere; this repo does not depend
on it and was built independently. Ground rule: this repo does not read or depend on
`~/sl/simpleread` — it implements the bridge contract from the task brief, not by diffing
against `simpleread`'s `src/utils/native-bridge/transport.ts` directly.

## Layout

```
lib/
  config.dart              simpleReadUrl — currently a PLACEHOLDER, see below
  main.dart                entrypoint; wires DeeplinkHandler before runApp()
  screens/webview_screen.dart   the only screen; hosts the WebView + JS channel
  navigation/               AppShell + nav state (native chrome around the webview)
  bridge/                   JS↔native contract — see below
test/                       unit tests, one file per bridge/navigation source file
integration_test/app_test.dart   on-device-only checks (real Firebase error, real
                                  local notification) — not part of `flutter test`'s
                                  default run
verification/                two iOS Simulator screenshots referenced from README
```

## Bridge contract

- **JS → native**: page calls `window.SimpleReadNativeBridge.postMessage(rawJsonString)`,
  `{id, event, payload}`, via a `JavaScriptChannel` named exactly `SimpleReadNativeBridge`.
- **native → JS**: shell calls `window.__simpleReadNativeBridgeDispatch(rawJsonString)`,
  same envelope shape.
- `bridge_message.dart` parses strictly (`BridgeParseException` on anything malformed).
- `bridge_dispatcher.dart` routes by event name to a request handler (returns a response)
  or a fire-and-forget handler (returns `null`). Both maps are pure Dart, no Flutter
  imports — testable without a widget pump or a real WebView.
- `bridge_events.dart` is the event catalog as named constants — check here first for
  "does event X exist" before grepping.

All 11 cataloged events have real handlers (none are stubs). Three are real but
**externally blocked** (need a Firebase project this PoC doesn't have); two are real but
**sandbox-limited** (no camera/no UI-automation on the build machine, not a code gap). The
full per-event table with exact status and evidence is in `README.md` under "Final status,
per event" — read that table before telling anyone an event is unimplemented.

## Known placeholders — do not report these as bugs, they are documented gaps

- `lib/config.dart`'s `simpleReadUrl` points at a Vercel staging deployment, not
  production. It has moved before; verify against the file, not against memory.
- `push.register` / `push.received`'s remote half needs a real Firebase project
  (`google-services.json` / `GoogleService-Info.plist`) that does not exist yet. The exact
  unmapped error without it: `FirebaseException: [core/not-initialized] ...`.
- No native home screen — the app opens straight into the webview. This reopens an App
  Store / Play Store minimum-functionality review risk the README flags explicitly; read
  "No native home screen" in `README.md` before assuming it's settled.

## Toolchain

Flutter 3.44.7 (stable), Dart 3.12.2.

```bash
flutter pub get
flutter analyze          # expect: No issues found!
flutter test              # expect: all passing, unit tests only — integration_test/
                           # is on-device only and not part of this run
```

`analysis_options.yaml` excludes `build/**`.

## Conventions

- Bridge handler files are named `<domain>_handler.dart`, one per event family, each with
  a matching `test/bridge/<domain>_handler_test.dart` covering every branch via an injected
  fake (never a real platform call in unit tests).
- Real external calls (network, camera, biometric, Firebase) are injected as function
  parameters or via platform-interface fakes, specifically so the handler logic stays
  testable without hardware or credentials.
- README's "Final status, per event" table and "On-device verification" section are
  updated with real command output, not paraphrased — treat unverified claims in a PR
  description with the same suspicion this repo's own history applies to itself.
