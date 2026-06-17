import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../services/biometric_services.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
import '../../data/database/db.dart';
import '../../services/extra_services.dart';

// classe de criptografia dos dados
class KeystoreService {
  static const _storage = FlutterSecureStorage();
  static const _dbKeyAlias = 'db_key';


  // funcao para logar com biometria
  static Future<bool> loginBIO() async {
    // chama funcao para validar biometria
    bool authentication = await BiometricServices.checkBiometric();

    if (authentication) {
      // tenta ler a chave salva no keyStore
      try {
        String? dbKey = await _storage.read(key: _dbKeyAlias);
        if (dbKey == null) return false;
        await DbService.init(dbKey);
        return true;

      } catch (e) {
        debugPrint(e.toString());
        return false;
      }

    } else{
      debugPrint("Erro ao autenticar usuário por biometria");
      return false;
    }
  }

  // funcao para logar via senha
  static Future<bool> loginPIN(String input) async{
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final AesGcm aes = AesGcm.with256bits();

    // tenta desencriptar blob1 do shared_preferences, se falha na autorizacao, tenta o blob2
    try {

      final List<int> salt1 = base64Decode(prefs.getString('salt1')!);
      final k1Bytes = await derivate(input, salt1);

      final k1 = SecretKey(k1Bytes);

      final SecretBox blob1 = SecretBox(
        base64Decode(prefs.getString('blob1_cipher')!), 
        nonce: base64Decode(prefs.getString('blob1_nonce')!), 
        mac: Mac(base64Decode(prefs.getString('blob1_mac')!))
      );

      final List<int> dbKeyByte = await aes.decrypt(blob1, secretKey: k1);
      final String dbKey = base64Encode(dbKeyByte);

      await DbService.init(dbKey);
      return true;

    } catch(e) {

      if (e is SecretBoxAuthenticationError) {
        final List<int> salt2 = base64Decode(prefs.getString('salt2')!);
        final k2Bytes = await derivate(input, salt2);

        final k2 = SecretKey(k2Bytes);

        final SecretBox blob1 = SecretBox(
          base64Decode(prefs.getString('blob2_cipher')!), 
          nonce: base64Decode(prefs.getString('blob2_nonce')!), 
          mac: Mac(base64Decode(prefs.getString('blob2_mac')!))
        );

        final List<int> dbKeyByte = await aes.decrypt(blob1, secretKey: k2);
        final String dbKey = base64Encode(dbKeyByte);

        await DbService.init(dbKey);
        return true;
        
      } else{
        debugPrint('Senha inválida.');
        return false;
      }
    }
  }
}