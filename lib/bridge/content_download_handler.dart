import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import 'webview_bridge_registry.dart';

/// The file downloaded to prove `content.download`'s download + progress +
/// local-storage path end to end.
///
/// SimpleRead has no real content URL yet (production content lives behind
/// auth, and per earlier team research this endpoint doesn't exist) -- so
/// this downloads a small, genuinely public, stable test file instead: the
/// W3C's long-standing "dummy.pdf" (served since 2007, `Content-Length`
/// present, fronted by Cloudflare -- checked with `curl -I` before picking
/// it, not assumed). Production wiring swaps this constant for a real
/// authenticated content URL once one exists; see README.md.
const String testContentDownloadUrl =
    'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf';

/// Signature for the actual download call, injected so [ContentDownloadHandler]
/// is unit-testable without real network access -- same DI shape as
/// [PushRegisterHandler]'s injected Firebase calls.
typedef DownloadFn = Future<void> Function(
  String url,
  String savePath, {
  required void Function(int received, int total) onReceiveProgress,
});

/// Real handler for `content.download` -- `dio` + `path_provider`. Also
/// drives `content.download.progress` (native -> JS) via
/// [WebviewBridgeRegistry] as bytes arrive.
class ContentDownloadHandler {
  ContentDownloadHandler({
    DownloadFn? download,
    Future<Directory> Function()? getSaveDirectory,
    void Function(String contentId, int percent)? onProgress,
  })  : _download = download ?? _dioDownload,
        _getSaveDirectory = getSaveDirectory ?? getApplicationDocumentsDirectory,
        _onProgress = onProgress ?? _defaultOnProgress;

  final DownloadFn _download;
  final Future<Directory> Function() _getSaveDirectory;
  final void Function(String contentId, int percent) _onProgress;

  /// Matches the `content.download` response shape from the contract:
  /// `{success, reason?}`.
  Future<Map<String, dynamic>> handle(Map<String, dynamic> payload) async {
    final contentId = payload['contentId'];
    if (contentId is! String || contentId.isEmpty) {
      return const {'success': false, 'reason': 'failed'};
    }

    try {
      final dir = await _getSaveDirectory();
      final savePath = '${dir.path}/simpleread_content_$contentId';
      await _download(
        testContentDownloadUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            final percent = ((received / total) * 100).round();
            _onProgress(contentId, percent);
          }
        },
      );
      return const {'success': true};
    } on Object {
      return const {'success': false, 'reason': 'failed'};
    }
  }

  static Future<void> _dioDownload(
    String url,
    String savePath, {
    required void Function(int, int) onReceiveProgress,
  }) {
    return Dio().download(url, savePath, onReceiveProgress: onReceiveProgress);
  }

  static void _defaultOnProgress(String contentId, int percent) {
    WebviewBridgeRegistry.instance.sendContentDownloadProgress(contentId, percent);
  }
}
