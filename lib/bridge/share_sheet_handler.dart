import 'package:share_plus/share_plus.dart';

/// Signature for the actual share call, injected for testability -- same DI
/// shape as [ContentDownloadHandler]'s injected download call.
typedef ShareFn = Future<ShareResult> Function(ShareParams params);

/// Real handler for `share.sheet` -- `share_plus`, the actively-maintained
/// Flutter Community package. React Native core's own `Share.share()`
/// covers this on that side; Flutter's SDK has no built-in equivalent, so a
/// package is required here.
class ShareSheetHandler {
  ShareSheetHandler({ShareFn? share})
      : _share = share ?? SharePlus.instance.share;

  final ShareFn _share;

  /// Matches the `share.sheet` response shape from the contract:
  /// `{success, reason?}`.
  Future<Map<String, dynamic>> handle(Map<String, dynamic> payload) async {
    final title = payload['title'];
    final url = payload['url'];
    if (title is! String || title.isEmpty || url is! String || url.isEmpty) {
      return const {'success': false, 'reason': 'failed'};
    }

    try {
      final result = await _share(ShareParams(title: title, text: url));
      if (result.status == ShareResultStatus.dismissed) {
        return const {'success': false, 'reason': 'user_cancelled'};
      }
      return const {'success': true};
    } on Object {
      return const {'success': false, 'reason': 'failed'};
    }
  }
}
