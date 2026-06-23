import 'dart:convert';
import 'dart:math';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../database/db.dart';
import '../models/senhas.dart';

class SenhaController {
  static const _storage    = FlutterSecureStorage();
  static const _dbKeyAlias = 'db_key';
  static final  _aes       = AesGcm.with256bits();

  // Recupera a DB_Key do Keystore para usar como chave de encriptação das senhas
  static Future<SecretKey> _getSecretKey() async {
    final dbKeyB64 = await _storage.read(key: _dbKeyAlias);
    if (dbKeyB64 == null) throw StateError('DB_Key não encontrada no Keystore.');
    return SecretKey(base64Decode(dbKeyB64));
  }

  // Salva uma nova senha encriptada no banco
  static Future<bool> salvar({
    required int    userID,
    required String titulo,
    required String usuario,
    required String senhaPlain,
    required String tipo,
    String url = '',
  }) async {
    if (titulo.trim().isEmpty || senhaPlain.isEmpty) {
      debugPrint('Título e senha são obrigatórios.');
      return false;
    }

    try {
      final secretKey = await _getSecretKey();

      final iv         = List<int>.generate(12, (_) => Random.secure().nextInt(256));
      final plainBytes = utf8.encode(senhaPlain);

      final secretBox = await _aes.encrypt(
        plainBytes,
        secretKey: secretKey,
        nonce: iv,
      );

      final senha = Senha(
        userID:     userID,
        titulo:     titulo,
        usuario:    usuario,
        cipherText: base64Encode(secretBox.cipherText),
        authTag:    base64Encode(secretBox.mac.bytes),
        iv:         base64Encode(secretBox.nonce),
        tipo: tipo,
        url: url,
      );

      final db = DbService.db;
      final id = await db.insert('senhas', senha.toMap()..remove('id'));
      debugPrint('Senha salva com id: $id');
      return true;

    } catch (e) {
      debugPrint('Erro ao salvar senha: $e');
      return false;
    }
  }

  // Edita uma senha existente (re-encripta com novo IV)
  static Future<bool> editar({
    required int    id,
    required String titulo,
    required String usuario,
    required String senhaPlain,
    required String tipo,
    String url = '',
  }) async {
    if (titulo.trim().isEmpty || senhaPlain.isEmpty) {
      debugPrint('Título e senha são obrigatórios.');
      return false;
    }

    try {
      final secretKey = await _getSecretKey();

      final iv         = List<int>.generate(12, (_) => Random.secure().nextInt(256));
      final plainBytes = utf8.encode(senhaPlain);

      final secretBox = await _aes.encrypt(
        plainBytes,
        secretKey: secretKey,
        nonce: iv,
      );

      final db = DbService.db;
      final updated = await db.update(
        'senhas',
        {
          'titulo':     titulo,
          'usuario':    usuario,
          'cipherText': base64Encode(secretBox.cipherText),
          'authTag':    base64Encode(secretBox.mac.bytes),
          'IV':         base64Encode(secretBox.nonce),
          'tipo': tipo,
          'url': url,
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      if (updated == 0) {
        debugPrint('Senha com id $id não encontrada.');
        return false;
      }
      return true;

    } catch (e) {
      debugPrint('Erro ao editar senha: $e');
      return false;
    }
  }

  // Busca todas as senhas do usuário (descriptografadas)
  static Future<List<Map<String, dynamic>>> buscarTodas(int userID) async {
    try {
      final db   = DbService.db;
      final rows = await db.query(
        'senhas',
        where: 'userID = ?',
        whereArgs: [userID],
      );

      final secretKey = await _getSecretKey();
      final result    = <Map<String, dynamic>>[];

      for (final row in rows) {
        final plain = await _decriptar(row, secretKey);
        if (plain != null) result.add(plain);
      }

      return result;

    } catch (e) {
      debugPrint('Erro ao buscar senhas: $e');
      return [];
    }
  }

  // Busca uma senha por id (descriptografada)
  static Future<Map<String, dynamic>?> buscarPorId(int id) async {
    try {
      final db   = DbService.db;
      final rows = await db.query(
        'senhas',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (rows.isEmpty) return null;

      final secretKey = await _getSecretKey();
      return await _decriptar(rows.first, secretKey);

    } catch (e) {
      debugPrint('Erro ao buscar senha por id: $e');
      return null;
    }
  }

  // Descriptografa uma linha do banco e retorna os dados legíveis
  static Future<Map<String, dynamic>?> _decriptar(
    Map<String, dynamic> row,
    SecretKey secretKey,
  ) async {
    try {
      final secretBox = SecretBox(
        base64Decode(row['cipherText'] as String),
        nonce: base64Decode(row['IV']         as String),
        mac:   Mac(base64Decode(row['authTag'] as String)),
      );

      final plainBytes = await _aes.decrypt(secretBox, secretKey: secretKey);
      final senhaPlain = utf8.decode(plainBytes);

      return {
        'id':      row['id'],
        'userID':  row['userID'],
        'titulo':  row['titulo'],
        'usuario': row['usuario'],
        'senha':   senhaPlain,
        'tipo': row['tipo'],
        'url': row['url'] ?? '',
      };

    } catch (e) {
      debugPrint('Falha ao decriptar entrada id ${row['id']}: $e');
      return null;
    }
  }

  // Deleta uma senha por id
  static Future<bool> deletar(int id) async {
    try {
      final db      = DbService.db;
      final deleted = await db.delete('senhas', where: 'id = ?', whereArgs: [id]);
      return deleted > 0;
    } catch (e) {
      debugPrint('Erro ao deletar senha: $e');
      return false;
    }
  }
}