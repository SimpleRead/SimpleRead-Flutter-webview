import 'dart:convert';

import 'package:image_picker/image_picker.dart';

/// Real handler for `camera.capture` -- `image_picker`'s camera source.
///
/// `image_picker` has no dedicated document-scanning API, so `document`
/// mode reuses the same camera capture path as `photo` (see README.md) --
/// this PoC does not fabricate a distinct document-scanner integration.
///
/// Camera hardware doesn't exist on iOS Simulator / Android Emulator
/// without webcam passthrough, so the actual capture call is untested
/// on-device here (see README.md); the base64-encoding/response-mapping
/// logic below is unit-tested with a fake `ImagePickerPlatform`.
class CameraCaptureHandler {
  CameraCaptureHandler({ImagePicker? imagePicker})
      : _imagePicker = imagePicker ?? ImagePicker();

  final ImagePicker _imagePicker;

  /// Matches the `camera.capture` response shape from the contract:
  /// `{success, imageBase64?, reason?}`.
  Future<Map<String, dynamic>> handle(Map<String, dynamic> payload) async {
    final mode = payload['mode'];
    if (mode != 'photo' && mode != 'document') {
      return const {'success': false, 'reason': 'failed'};
    }

    try {
      final XFile? file = await _imagePicker.pickImage(source: ImageSource.camera);
      if (file == null) {
        return const {'success': false, 'reason': 'user_cancelled'};
      }
      final bytes = await file.readAsBytes();
      return {'success': true, 'imageBase64': base64Encode(bytes)};
    } on Object {
      // Real device/platform failure (no camera hardware, permission
      // denied, plugin already in use, ...) -- mapped to the contract's
      // generic failure reason rather than propagated.
      return const {'success': false, 'reason': 'failed'};
    }
  }
}
