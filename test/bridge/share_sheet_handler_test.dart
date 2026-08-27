import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';
import 'package:simpleread_flutter_shell/bridge/share_sheet_handler.dart';

void main() {
  group('ShareSheetHandler.handle', () {
    test('returns failed when title is missing', () async {
      final handler = ShareSheetHandler(
        share: (params) async => const ShareResult('', ShareResultStatus.success),
      );

      final result = await handler.handle({'url': 'https://simpleread.app'});

      expect(result, {'success': false, 'reason': 'failed'});
    });

    test('returns failed when url is missing', () async {
      final handler = ShareSheetHandler(
        share: (params) async => const ShareResult('', ShareResultStatus.success),
      );

      final result = await handler.handle({'title': 'Chapter 1'});

      expect(result, {'success': false, 'reason': 'failed'});
    });

    test('shares the title and url and returns success', () async {
      ShareParams? captured;
      final handler = ShareSheetHandler(
        share: (params) async {
          captured = params;
          return const ShareResult('', ShareResultStatus.success);
        },
      );

      final result = await handler.handle({
        'title': 'Chapter 1',
        'url': 'https://simpleread.app/read/chapter-1',
      });

      expect(result, {'success': true});
      expect(captured?.title, 'Chapter 1');
      expect(captured?.text, 'https://simpleread.app/read/chapter-1');
    });

    test('returns user_cancelled when the share sheet is dismissed', () async {
      final handler = ShareSheetHandler(
        share: (params) async =>
            const ShareResult('', ShareResultStatus.dismissed),
      );

      final result = await handler.handle({
        'title': 'Chapter 1',
        'url': 'https://simpleread.app/read/chapter-1',
      });

      expect(result, {'success': false, 'reason': 'user_cancelled'});
    });

    test('returns failed when the platform call throws', () async {
      final handler = ShareSheetHandler(
        share: (params) async => throw Exception('platform error'),
      );

      final result = await handler.handle({
        'title': 'Chapter 1',
        'url': 'https://simpleread.app/read/chapter-1',
      });

      expect(result, {'success': false, 'reason': 'failed'});
    });
  });
}
