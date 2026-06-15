import 'dart:math';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'biometric_services.dart';

class KeystoreService {
  static const _storage = FlutterSecureStorage();
  static const _dbKeyAlias = 'db_key';

  static Future<String> createDbKey() async{
    final String key;
    final bytes = List<int>.generate(32, (_) => Random.secure().nextInt(256));
    key = base64UrlEncode(bytes);
    await _storage.write(key: _dbKeyAlias, value: key);

    return key;
  }

  static Future<String?> getDbKey() async {
    bool authentication = await BiometricServices.checkBiometric();

    if (authentication) {
      String? dbKey = await _storage.read(key: _dbKeyAlias);
      return dbKey;
      
    } else{
      return null;
    }
  }
}