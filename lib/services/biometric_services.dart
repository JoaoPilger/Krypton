import 'package:local_auth/local_auth.dart';

class BiometricServices {
  static final LocalAuthentication _auth = LocalAuthentication();
  
  // funcao que verifica se tem biometria, e se tiver, exige-a
  static Future<bool> checkBiometric() async {
    // verifica suporte a biometria no hardware
    final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
    final bool canAuthenticate =
        canAuthenticateWithBiometrics || await _auth.isDeviceSupported();

    if (!canAuthenticate) return false;

    // verifica se tem biometria cadastrada no dispositivo
    final List<BiometricType> availableBiometrics =
        await _auth.getAvailableBiometrics();

    if (availableBiometrics.isEmpty) return false;

    try {
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'Autentique para acessar o aplicativo.',
      );
      return didAuthenticate;

    } catch (e) {
      return false;
    }
  }
}
