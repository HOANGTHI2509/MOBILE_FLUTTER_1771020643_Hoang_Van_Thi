import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

class BiometricService {
  static final LocalAuthentication auth = LocalAuthentication();

  static Future<bool> authenticate() async {
    try {
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      if (!canAuthenticateWithBiometrics) {
        return false;
      }

      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Vui lòng xác thực vân tay để đăng nhập nhanh',
      );
      return didAuthenticate;
    } on PlatformException catch (_) {
      return false;
    }
  }
}
