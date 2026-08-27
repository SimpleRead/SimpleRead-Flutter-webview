import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:simpleread_flutter_shell/bridge/content_download_handler.dart';

void main() {
  group('ContentDownloadHandler.handle', () {
    test('returns failed when contentId is missing', () async {
      final handler = ContentDownloadHandler(
        download: (url, savePath, {required onReceiveProgress}) async {},
        getSaveDirectory: () async => Directory.systemTemp,
      );

      final result = await handler.handle({});

      expect(result, {'success': false, 'reason': 'failed'});
    });

    test('downloads to <directory>/simpleread_content_<contentId> and '
        'reports success', () async {
      String? capturedUrl;
      String? capturedSavePath;

      final handler = ContentDownloadHandler(
        download: (url, savePath, {required onReceiveProgress}) async {
          capturedUrl = url;
          capturedSavePath = savePath;
          onReceiveProgress(50, 100);
          onReceiveProgress(100, 100);
        },
        getSaveDirectory: () async => Directory('/tmp/simpleread-test-dir'),
      );

      final result = await handler.handle({'contentId': 'chapter-1'});

      expect(result, {'success': true});
      expect(capturedUrl, testContentDownloadUrl);
      expect(
        capturedSavePath,
        '/tmp/simpleread-test-dir/simpleread_content_chapter-1',
      );
    });

    test('forwards receive-progress ticks as percentages via onProgress',
        () async {
      final observed = <int>[];

      final handler = ContentDownloadHandler(
        download: (url, savePath, {required onReceiveProgress}) async {
          onReceiveProgress(25, 100);
          onReceiveProgress(100, 100);
        },
        getSaveDirectory: () async => Directory.systemTemp,
        onProgress: (contentId, percent) => observed.add(percent),
      );

      await handler.handle({'contentId': 'chapter-1'});

      expect(observed, [25, 100]);
    });

    test('ignores a progress tick with an unknown total (-1)', () async {
      final observed = <int>[];

      final handler = ContentDownloadHandler(
        download: (url, savePath, {required onReceiveProgress}) async {
          onReceiveProgress(10, -1);
        },
        getSaveDirectory: () async => Directory.systemTemp,
        onProgress: (contentId, percent) => observed.add(percent),
      );

      await handler.handle({'contentId': 'chapter-1'});

      expect(observed, isEmpty);
    });

    test('returns failed when the download throws', () async {
      final handler = ContentDownloadHandler(
        download: (url, savePath, {required onReceiveProgress}) async {
          throw Exception('network unreachable');
        },
        getSaveDirectory: () async => Directory.systemTemp,
      );

      final result = await handler.handle({'contentId': 'chapter-1'});

      expect(result, {'success': false, 'reason': 'failed'});
    });
  });
}
