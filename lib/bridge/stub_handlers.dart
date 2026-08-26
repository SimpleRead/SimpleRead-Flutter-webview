/// Stubbed request/response handlers named in the contract but not wired to
/// anything real in this PoC. Each returns immediately with `success: false`
/// and a reason, rather than hanging or fabricating a working result.
library;

/// TODO(push.register): wire to a real APNs/FCM project. Not required for
/// this bridge-pattern PoC — see README.md.
Future<Map<String, dynamic>> handlePushRegisterStub(
  Map<String, dynamic> payload,
) async {
  return const {
    'success': false,
    'reason': 'not_implemented_stub',
  };
}

/// TODO(camera.capture): wire to `image_picker` or a native camera view.
/// Not required for this bridge-pattern PoC — see README.md.
Future<Map<String, dynamic>> handleCameraCaptureStub(
  Map<String, dynamic> payload,
) async {
  return const {
    'success': false,
    'reason': 'not_implemented_stub',
  };
}
