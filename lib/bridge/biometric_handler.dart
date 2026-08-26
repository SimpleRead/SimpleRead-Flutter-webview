import 'package:local_auth/local_auth.dart';

/// Real handler for `auth.biometric` — prompts the device's actual
/// Face ID / Touch ID / fingerprint UI via `local_auth`, no stub.
///
/// The request payload's `userId` is part of the bridge contract but this
/// PoC has no backend session to attach the result to, so it is only
/// validated as present and never sent anywhere.
class BiometricAuthHandler {
  final LocalAuthentication _localAuth;

  BiometricAuthHandler({LocalAuthentication? localAuth})
      : _localAuth = localAuth ?? LocalAuthentication();

  /// Matches the `auth.biometric` response shape from the contract:
  /// `{success, reason?: 'not_enrolled' | 'user_cancelled' | 'failed'}`.
  Future<Map<String, dynamic>> handle(Map<String, dynamic> payload) async {
    final userId = payload['userId'];
    if (userId is! String || userId.isEmpty) {
      return const {'success': false, 'reason': 'failed'};
    }

    final isSupported = await _localAuth.isDeviceSupported();
    if (!isSupported) {
      return const {'success': false, 'reason': 'not_enrolled'};
    }

    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to continue in SimpleRead',
      );
      if (authenticated) {
        return const {'success': true};
      }
      // Platforms that return false rather than throwing on a failed
      // challenge land here; treat it the same as a user cancel.
      return const {'success': false, 'reason': 'user_cancelled'};
    } on LocalAuthException catch (e) {
      switch (e.code) {
        case LocalAuthExceptionCode.userCanceled:
        case LocalAuthExceptionCode.userRequestedFallback:
          return const {'success': false, 'reason': 'user_cancelled'};
        case LocalAuthExceptionCode.noCredentialsSet:
        case LocalAuthExceptionCode.noBiometricsEnrolled:
        case LocalAuthExceptionCode.noBiometricHardware:
          return const {'success': false, 'reason': 'not_enrolled'};
        default:
          return const {'success': false, 'reason': 'failed'};
      }
    }
  }
}
