import 'package:local_auth/local_auth.dart';

class BiometricServices {
  static final LocalAuthentication _auth = LocalAuthentication();
  
  // funcao que verifica se tem biometria, e se tiver, exige-a
  static Future<bool> checkBiometric() async{
    final List<BiometricType> availableBiometrics = await _auth.getAvailableBiometrics();
    
    if (availableBiometrics.isNotEmpty) {
      try {
        final bool didAuthenticate = await _auth.authenticate(
          localizedReason: 'Autentique para acessar o aplicativo.',
          biometricOnly: true
        );
        return didAuthenticate;

      } catch (e) {
        return false;
      }
    }
    return false;
  }
}
