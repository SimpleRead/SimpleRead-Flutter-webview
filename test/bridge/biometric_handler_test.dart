import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth_platform_interface/local_auth_platform_interface.dart';
import 'package:simpleread_flutter_shell/bridge/biometric_handler.dart';

/// A fake platform implementation, substituted via
/// `LocalAuthPlatform.instance`, so the handler's branching can be tested
/// without a real device/simulator biometric prompt.
class _FakeLocalAuthPlatform extends LocalAuthPlatform {
  _FakeLocalAuthPlatform({
    this.deviceSupported = true,
    this.authenticateResult,
    this.authenticateError,
  });

  final bool deviceSupported;
  final bool? authenticateResult;
  final LocalAuthException? authenticateError;

  @override
  Future<bool> isDeviceSupported() async => deviceSupported;

  @override
  Future<bool> deviceSupportsBiometrics() async => deviceSupported;

  @override
  Future<bool> authenticate({
    required String localizedReason,
    required Iterable<AuthMessages> authMessages,
    AuthenticationOptions options = const AuthenticationOptions(),
  }) async {
    if (authenticateError != null) {
      throw authenticateError!;
    }
    return authenticateResult!;
  }
}

void main() {
  final handler = BiometricAuthHandler();

  group('BiometricAuthHandler.handle', () {
    test('returns failed when userId is missing from the payload', () async {
      final result = await handler.handle({});
      expect(result, {'success': false, 'reason': 'failed'});
    });

    test('returns failed when userId is not a string', () async {
      final result = await handler.handle({'userId': 42});
      expect(result, {'success': false, 'reason': 'failed'});
    });

    test('returns not_enrolled when the device is not supported', () async {
      LocalAuthPlatform.instance = _FakeLocalAuthPlatform(
        deviceSupported: false,
      );

      final result = await handler.handle({'userId': 'u1'});

      expect(result, {'success': false, 'reason': 'not_enrolled'});
    });

    test('returns success: true when authenticate() succeeds', () async {
      LocalAuthPlatform.instance = _FakeLocalAuthPlatform(
        authenticateResult: true,
      );

      final result = await handler.handle({'userId': 'u1'});

      expect(result, {'success': true});
    });

    test(
        'returns user_cancelled when authenticate() completes with false '
        '(no side effects)', () async {
      LocalAuthPlatform.instance = _FakeLocalAuthPlatform(
        authenticateResult: false,
      );

      final result = await handler.handle({'userId': 'u1'});

      expect(result, {'success': false, 'reason': 'user_cancelled'});
    });

    test('maps LocalAuthExceptionCode.userCanceled to user_cancelled',
        () async {
      LocalAuthPlatform.instance = _FakeLocalAuthPlatform(
        authenticateError: const LocalAuthException(
          code: LocalAuthExceptionCode.userCanceled,
        ),
      );

      final result = await handler.handle({'userId': 'u1'});

      expect(result, {'success': false, 'reason': 'user_cancelled'});
    });

    test('maps LocalAuthExceptionCode.noBiometricsEnrolled to not_enrolled',
        () async {
      LocalAuthPlatform.instance = _FakeLocalAuthPlatform(
        authenticateError: const LocalAuthException(
          code: LocalAuthExceptionCode.noBiometricsEnrolled,
        ),
      );

      final result = await handler.handle({'userId': 'u1'});

      expect(result, {'success': false, 'reason': 'not_enrolled'});
    });

    test('maps an unrelated LocalAuthExceptionCode to failed', () async {
      LocalAuthPlatform.instance = _FakeLocalAuthPlatform(
        authenticateError: const LocalAuthException(
          code: LocalAuthExceptionCode.deviceError,
        ),
      );

      final result = await handler.handle({'userId': 'u1'});

      expect(result, {'success': false, 'reason': 'failed'});
    });
  });
}
