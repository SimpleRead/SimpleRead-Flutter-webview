import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../config.dart';
import '../bridge/bridge_dispatcher.dart';
import '../bridge/bridge_events.dart';
import '../bridge/bridge_message.dart';
import '../bridge/biometric_handler.dart';
import '../bridge/calendar_event_handler.dart';
import '../bridge/camera_capture_handler.dart';
import '../bridge/content_download_handler.dart';
import '../bridge/native_to_js.dart';
import '../bridge/playback_state_store.dart';
import '../bridge/push_register_handler.dart';
import '../bridge/share_sheet_handler.dart';
import '../bridge/webview_bridge_registry.dart';
import '../navigation/nav_state_store.dart';

/// The webview screen: loads the live SimpleRead site UNCHANGED and wires
/// the `SimpleReadNativeBridge` JavaScriptChannel to the bridge dispatcher.
///
/// This is the "webview wrapper" half of the hybrid shell — the home screen
/// is the plain-native half.
class WebviewScreen extends StatefulWidget {
  const WebviewScreen({super.key});

  /// Holds the latest `navigation.state` event. Static (rather than an
  /// instance field, unlike [PlaybackStateStore] below) because `AppShell`
  /// wraps this screen and needs to read it from outside the widget tree --
  /// same problem [WebviewBridgeRegistry] solves for the `WebViewController`,
  /// same fix: a long-lived singleton this screen writes into, read from
  /// outside. Unlike that registry, the store itself (not a wrapper) is the
  /// singleton, since `NavStateStore`'s public constructor already needs to
  /// stay unnamed for `NavStateStore()` to keep working in existing tests.
  static final NavStateStore navStateStore = NavStateStore();

  @override
  State<WebviewScreen> createState() => _WebviewScreenState();
}

class _WebviewScreenState extends State<WebviewScreen> {
  late final WebViewController _controller;
  final BridgeDispatcher _dispatcher = BridgeDispatcher();
  final PlaybackStateStore _playbackState = PlaybackStateStore();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _registerHandlers();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        // Must be named exactly this — the page's
        // window.SimpleReadNativeBridge.postMessage(...) calls land here.
        'SimpleReadNativeBridge',
        onMessageReceived: _onMessageFromJs,
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
        ),
      )
      ..loadRequest(Uri.parse(simpleReadUrl));

    // Let the home screen's native "Pause playback" button reach this
    // webview's JS runtime.
    WebviewBridgeRegistry.instance.value = _controller;
  }

  void _registerHandlers() {
    _dispatcher.registerRequestHandler(
      BridgeRequestEvents.authBiometric,
      BiometricAuthHandler().handle,
    );
    _dispatcher.registerRequestHandler(
      BridgeRequestEvents.pushRegister,
      PushRegisterHandler().handle,
    );
    _dispatcher.registerRequestHandler(
      BridgeRequestEvents.cameraCapture,
      CameraCaptureHandler().handle,
    );
    _dispatcher.registerRequestHandler(
      BridgeRequestEvents.contentDownload,
      ContentDownloadHandler().handle,
    );
    _dispatcher.registerRequestHandler(
      BridgeRequestEvents.shareSheet,
      ShareSheetHandler().handle,
    );
    _dispatcher.registerRequestHandler(
      BridgeRequestEvents.calendarEvent,
      CalendarEventHandler().handle,
    );
    _dispatcher.registerFireAndForgetHandler(
      BridgeFireAndForgetEvents.mediaPlaybackState,
      _playbackState.handle,
    );
    _dispatcher.registerFireAndForgetHandler(
      BridgeFireAndForgetEvents.navigationState,
      WebviewScreen.navStateStore.handle,
    );
  }

  Future<void> _onMessageFromJs(JavaScriptMessage message) async {
    try {
      final responseJson = await _dispatcher.handleIncoming(message.message);
      if (responseJson != null) {
        await _controller.runJavaScript(
          NativeToJs.dispatchScriptForRawJson(responseJson),
        );
      }
    } on BridgeParseException catch (e) {
      // Malformed message from the page — surface it in debug output rather
      // than crashing the webview.
      debugPrint('SimpleReadNativeBridge: dropped malformed message: $e');
    }
  }

  @override
  void dispose() {
    // Clear the registry entry only if it's still pointing at this screen's
    // controller (guards against a stale clear if a second webview screen
    // were ever pushed).
    if (WebviewBridgeRegistry.instance.value == _controller) {
      WebviewBridgeRegistry.instance.value = null;
    }
    _playbackState.dispose();
    // navStateStore is NOT disposed here: unlike _playbackState it's a
    // static singleton AppShell holds a listener on for the app's whole
    // life, not an instance scoped to this screen.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SimpleRead'),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ValueListenableBuilder<PlaybackState?>(
              valueListenable: _playbackState,
              builder: (context, state, _) {
                if (state == null) return const SizedBox.shrink();
                return Container(
                  color: Colors.black87,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Text(
                    'media.playback.state: "${state.title}" '
                    '(${state.isPlaying ? "playing" : "paused"})',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
