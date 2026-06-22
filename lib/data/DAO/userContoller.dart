import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../database/db.dart';
import '../models/user.dart';
import 'dart:math';
import 'package:cryptography/cryptography.dart';
import '../../services/extra_services.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserController {
  // Cadastro: gera as chaves, abre o banco e insere o usuário
  
  static Future<bool> cadastrar({
    required String nome,
    required String senhaMestre,
  }) async {

    // confere se já existe um usuario cadastrado e bloqueia novo cadastro
    bool authentication = await DbService.userRegistered();
    if (authentication) {
      return false;
    }

    if (nome.trim().isEmpty || senhaMestre.isEmpty) {
      debugPrint('Campos obrigatórios não preenchidos.');
      return false;
    }

    try {
      // Gera DB_Key, blobs, salts e abre o banco (DbService.init é chamado internamente)
      await registerDbKey(senhaMestre);

      final db   = DbService.db;
      final user = User(nome: nome);

      final id = await db.insert('users', user.toMap()..remove('id'));
      debugPrint('Usuário criado com id: $id');
      
      return true;

    } catch (e) {
      debugPrint('Erro no cadastro: $e');
      return false;
    }
  }

  // Busca o usuário logado (assumindo um único usuário por banco)
  static Future<User?> getUser() async {
    try {
      final db   = DbService.db;
      final rows = await db.query('users', limit: 1);
      if (rows.isEmpty) return null;
      return User.fromMap(rows.first);

    } catch (e) {
      debugPrint('Erro ao buscar usuário: $e');
      return null;
    }
  }
}

// funcao de criar e salvar senha do DB
Future<void> registerDbKey(String senhaMestre) async{
  const dbKeyAlias = 'db_key';
  const storage = FlutterSecureStorage();

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
    await storage.write(key: dbKeyAlias, value: dbKey);

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
      
  } catch (e) {
    debugPrint(e.toString());
  }
    
}