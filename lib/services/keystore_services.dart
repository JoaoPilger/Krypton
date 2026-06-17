import 'dart:math';
import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'biometric_services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
import '../data/database/db.dart';

// classe de criptografia dos dados
class KeystoreService {
  static const _storage = FlutterSecureStorage();
  static const _dbKeyAlias = 'db_key';

  // funcao de criar e salvar senha do DB
  static Future<void> registerDbKey(String senhaMestre, String email) async{

    try {
      // cria a senha do DB como string e como lista de 32 bytes
      final String dbKey;
      final dbKeyBytes = List<int>.generate(32, (_) => Random.secure().nextInt(256));
      dbKey = base64UrlEncode(dbKeyBytes);

      final String dbKeyRecup;
      final dbKeyRecupBytes = List<int>.generate(32, (_) => Random.secure().nextInt(256));
      dbKeyRecup = base64UrlEncode(dbKeyRecupBytes);
      
      await DbService.init(dbKey);

      // Salva na Kestore do celular para desbloquear por biometria
      await _storage.write(key: _dbKeyAlias, value: dbKey);

      // códigos para criptografar as senhas de acesso
      final salt1 = List<int>.generate(16, (_) => Random.secure().nextInt(256));
      final salt2 = List<int>.generate(16, (_) => Random.secure().nextInt(256));
      
      // senhas derivadas e criptografadas com argon2
      final k1Bytes = await derivate(senhaMestre, salt1);
      final k2Bytes = await derivate(dbKeyRecup, salt2);

      // transforma os Ks de Byte para SecretKey, para encaixar no encrypt do AES
      final k1 = SecretKey(k1Bytes);
      final k2 = SecretKey(k2Bytes);

      // criptografia com AES-GCM
      final aes = AesGcm.with256bits();

      final blob1 = await aes.encrypt(dbKeyBytes, secretKey: k1);
      final blob2 = await aes.encrypt(dbKeyRecupBytes, secretKey: k2);

      // salvando blobs e salts no shared_preferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      await prefs.setString('blob1_cipher', base64Encode(blob1.cipherText));
      await prefs.setString('blob1_mac',    base64Encode(blob1.mac.bytes));
      await prefs.setString('blob1_nonce',  base64Encode(blob1.nonce));

      await prefs.setString('blob2_cipher', base64Encode(blob2.cipherText));
      await prefs.setString('blob2_mac',    base64Encode(blob2.mac.bytes));
      await prefs.setString('blob2_nonce',  base64Encode(blob2.nonce));
      
      await prefs.setString('salt1', base64Encode(salt1));
      await prefs.setString('salt2', base64Encode(salt2));

      // envia senha de recuperacao para o email registrado
      sendEmail(dbKeyRecup, email);
      
    } catch (e) {
      debugPrint(e.toString());
    }
    
  }

  // funcao para logar com biometria
  static Future<String?> dbValidationBIO() async {
    // chama funcao para validar biometria
    bool authentication = await BiometricServices.checkBiometric();

    if (authentication) {
      // tenta ler a chave salva no keyStore
      try {
        String? dbKey = await _storage.read(key: _dbKeyAlias);
        return dbKey;

      } catch (e) {
        debugPrint(e.toString());
        return null;
      }

    } else{
      debugPrint("Erro ao autenticar usuário por biometria");
      return null;
    }
  }

  // funcao para logar via senha
  static void dbValidationPIN(String input) async{
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
        
      } else{
        debugPrint('Senha inválida.');
      }
    }
  }
}

// funcao para derivar chaves
Future<List<int>> derivate(String input, List<int> salt) async{
  final argon2 = Argon2id(
    hashLength: 32,
    memory: 64 * 1024,
    parallelism: 1,
    iterations: 3
  );

  final SecretKey secretKey = await argon2.deriveKey(
    secretKey: SecretKey(utf8.encode(input)),
    nonce: salt
  );

  return await secretKey.extractBytes();
}

// funcao para enviar email para si mesmo
void sendEmail(String dbKeyRecup, String email){
  final Uri emailLauncher = Uri(
    scheme: 'mailto',
    path: email,
    queryParameters: {
      'subject': 'Senha de recuperação Krypton',
      'body': dbKeyRecup
    }
  );

  launchUrl(emailLauncher);
}