import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:simpleread_flutter_shell/bridge/camera_capture_handler.dart';

/// A fake platform implementation, substituted via
/// `ImagePickerPlatform.instance`, so the handler's branching can be tested
/// without real camera hardware -- same pattern as
/// `_FakeLocalAuthPlatform` in biometric_handler_test.dart.
class _FakeImagePickerPlatform extends ImagePickerPlatform {
  _FakeImagePickerPlatform({this.imageToReturn, this.errorToThrow});

  final XFile? imageToReturn;
  final Object? errorToThrow;

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return imageToReturn;
  }
}

void main() {
  final handler = CameraCaptureHandler();

  group('CameraCaptureHandler.handle', () {
    test('returns failed when mode is missing', () async {
      final result = await handler.handle({});
      expect(result, {'success': false, 'reason': 'failed'});
    });

    test('returns failed when mode is neither photo nor document', () async {
      final result = await handler.handle({'mode': 'video'});
      expect(result, {'success': false, 'reason': 'failed'});
    });

    test('returns success with base64 image data for mode: photo', () async {
      final bytes = Uint8List.fromList([1, 2, 3, 4]);
      ImagePickerPlatform.instance = _FakeImagePickerPlatform(
        imageToReturn: XFile.fromData(bytes, name: 'photo.png'),
      );

      final result = await handler.handle({'mode': 'photo'});

      expect(result['success'], true);
      expect(result['imageBase64'], base64Encode(bytes));
    });

    test('mode: document reuses the same camera capture path as photo',
        () async {
      final bytes = Uint8List.fromList([9, 9, 9]);
      ImagePickerPlatform.instance = _FakeImagePickerPlatform(
        imageToReturn: XFile.fromData(bytes, name: 'doc.png'),
      );

      final result = await handler.handle({'mode': 'document'});

      expect(result['success'], true);
      expect(result['imageBase64'], base64Encode(bytes));
    });

    test('returns user_cancelled when the picker returns null', () async {
      ImagePickerPlatform.instance = _FakeImagePickerPlatform(
        imageToReturn: null,
      );

      final result = await handler.handle({'mode': 'photo'});

      expect(result, {'success': false, 'reason': 'user_cancelled'});
    });

    test('returns failed when the platform throws (no camera hardware, '
        'permission denied, ...)', () async {
      ImagePickerPlatform.instance = _FakeImagePickerPlatform(
        errorToThrow: Exception('camera unavailable'),
      );

      final result = await handler.handle({'mode': 'photo'});

      expect(result, {'success': false, 'reason': 'failed'});
    });
  });
}
