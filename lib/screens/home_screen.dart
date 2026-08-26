import 'package:flutter/material.dart';

import '../bridge/webview_bridge_registry.dart';
import 'webview_screen.dart';

/// Plain native Flutter home screen — no webview here. This is the "more
/// than a repackaged website" surface the hybrid-shell pattern relies on to
/// lower app-store minimum-functionality rejection risk.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _openSimpleRead(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const WebviewScreen()),
    );
  }

  Future<void> _pausePlayback(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final sent = await WebviewBridgeRegistry.instance.sendPlaybackControl('pause');
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          sent
              ? 'Sent media.playback.control { action: "pause" } to the page.'
              : 'No SimpleRead webview is open — open it first, then pause.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SimpleRead Shell')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.menu_book, size: 64),
              const SizedBox(height: 16),
              const Text(
                'SimpleRead Native Shell',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Hybrid native shell + embedded WebView proof of concept.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                key: const Key('open_simpleread_button'),
                onPressed: () => _openSimpleRead(context),
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open SimpleRead'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                key: const Key('pause_playback_button'),
                onPressed: () => _pausePlayback(context),
                icon: const Icon(Icons.pause_circle_outline),
                label: const Text('Pause playback'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
