import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/db.dart';
import '../../services/keystore_services.dart';

class AuthController {

  // Login por senha mestre ou chave de recuperação
  static Future<bool> loginPIN(String input) async {
    final prefs = await SharedPreferences.getInstance();
    final aes   = AesGcm.with256bits();

    // Tenta blob1 (senha mestre)
    try {
      final salt1    = base64Decode(prefs.getString('salt1')!);
      final k1       = SecretKey(await derivate(input, salt1));
      final blob1    = SecretBox(
        base64Decode(prefs.getString('blob1_cipher')!),
        nonce: base64Decode(prefs.getString('blob1_nonce')!),
        mac:   Mac(base64Decode(prefs.getString('blob1_mac')!)),
      );
      final dbKeyBytes = await aes.decrypt(blob1, secretKey: k1);
      final dbKey      = base64Encode(dbKeyBytes);

      await DbService.init(dbKey);
      return true;

    } catch (e) {
      if (e is! SecretBoxAuthenticationError) {
        debugPrint('Erro inesperado no blob1: $e');
        return false;
      }
    }

    // Tenta blob2 (chave de recuperação)
    try {
      final prefs = await SharedPreferences.getInstance();
      final salt2    = base64Decode(prefs.getString('salt2')!);
      final k2       = SecretKey(await derivate(input, salt2));
      final blob2    = SecretBox(
        base64Decode(prefs.getString('blob2_cipher')!),
        nonce: base64Decode(prefs.getString('blob2_nonce')!),
        mac:   Mac(base64Decode(prefs.getString('blob2_mac')!)),
      );
      final dbKeyBytes = await aes.decrypt(blob2, secretKey: k2);
      final dbKey      = base64Encode(dbKeyBytes);

      await DbService.init(dbKey);
      return true;

    } catch (e) {
      if (e is SecretBoxAuthenticationError) {
        debugPrint('Credencial inválida.');
      } else {
        debugPrint('Erro inesperado no blob2: $e');
      }
      return false;
    }
  }

  // Login por biometria (FaceID / Digital)
  static Future<bool> loginBIO() async {
    try {
      final dbKey = await KeystoreService.dbValidationBIO();
      if (dbKey == null) return false;

      await DbService.init(dbKey);
      return true;

    } catch (e) {
      debugPrint('Erro no login biométrico: $e');
      return false;
    }
  }

  // Logout
  static Future<void> logout() async {
    await DbService.close();
  }
}