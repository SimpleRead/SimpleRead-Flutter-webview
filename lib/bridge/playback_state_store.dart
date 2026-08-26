import 'package:flutter/foundation.dart';

/// Holds the last `media.playback.state` fire-and-forget event received
/// from JS: `{title: string, isPlaying: boolean}`.
///
/// A `ValueNotifier` rather than a full state-management library — this PoC
/// only needs the webview screen to reflect the latest state it was told
/// about, nothing more.
class PlaybackStateStore extends ValueNotifier<PlaybackState?> {
  PlaybackStateStore() : super(null);

  void handle(Map<String, dynamic> payload) {
    final title = payload['title'];
    final isPlaying = payload['isPlaying'];
    if (title is String && isPlaying is bool) {
      value = PlaybackState(title: title, isPlaying: isPlaying);
    }
  }
}

@immutable
class PlaybackState {
  final String title;
  final bool isPlaying;

  const PlaybackState({required this.title, required this.isPlaying});
}
