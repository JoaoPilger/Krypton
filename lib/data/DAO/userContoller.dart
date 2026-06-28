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

  static Future<bool> cadastrar({
    required String nome,
    required String senhaMestre,
  }) async {

    // Bloqueia segundo cadastro
    // Obs: na primeira execução o banco ainda não está aberto,
    // então userRegistered retorna false corretamente.
    bool jaRegistrado = await DbService.userRegistered();
    if (jaRegistrado) return false;

    if (nome.trim().isEmpty || senhaMestre.isEmpty) {
      debugPrint('Campos obrigatórios não preenchidos.');
      return false;
    }

    try {
      await registerDbKey(senhaMestre); // abre o banco internamente

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

// Gera a DB_Key, os blobs criptografados e abre o banco
Future<void> registerDbKey(String senhaMestre) async {
  const dbKeyAlias = 'db_key';
  const storage    = FlutterSecureStorage();

  try {
    // DB_Key: 32 bytes aleatórios codificados em base64Url
    final dbKeyBytes = List<int>.generate(32, (_) => Random.secure().nextInt(256));
    final dbKey      = base64UrlEncode(dbKeyBytes);

    // Chave de recuperação: 32 bytes independentes
    final dbKeyRecupBytes = List<int>.generate(32, (_) => Random.secure().nextInt(256));
    final dbKeyRecup      = base64UrlEncode(dbKeyRecupBytes);

    // Abre o banco com a DB_Key (AppDatabase → PRAGMA key via hex)
    await DbService.init(dbKey);

    // Salva no Keystore para login por biometria
    await storage.write(key: dbKeyAlias, value: dbKey);

    // Salts independentes para cada blob
    final salt1 = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    final salt2 = List<int>.generate(16, (_) => Random.secure().nextInt(256));

    // Deriva k1 da senha mestre e k2 da chave de recuperação via Argon2id
    final k1Bytes = await derivate(senhaMestre, salt1);
    final k2Bytes = await derivate(dbKeyRecup, salt2);

    final k1  = SecretKey(k1Bytes);
    final k2  = SecretKey(k2Bytes);
    final aes = AesGcm.with256bits();

    // Encripta a DB_Key com cada chave derivada
    final blob1 = await aes.encrypt(dbKeyBytes,      secretKey: k1);
    final blob2 = await aes.encrypt(dbKeyRecupBytes, secretKey: k2);

    // Persiste blobs e salts no SharedPreferences
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