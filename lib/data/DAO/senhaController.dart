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

  static Future<SecretKey> _getSecretKey() async {
    final dbKeyB64 = await _storage.read(key: _dbKeyAlias);
    if (dbKeyB64 == null) throw StateError('DB_Key não encontrada no Keystore.');
    final normalized = dbKeyB64.replaceAll('-', '+').replaceAll('_', '/');
    final padded = normalized.padRight(
      normalized.length + (4 - normalized.length % 4) % 4, '=',
    );
    return SecretKey(base64Decode(padded));
  }

  static Future<bool> salvar({
    required int    userID,
    required String titulo,
    required String usuario,
    required String senhaPlain,
    required String tipo,
    String url = '',
    bool favorito = false,
    String? imagemPath,
  }) async {
    if (titulo.trim().isEmpty || senhaPlain.isEmpty) {
      debugPrint('Título e senha são obrigatórios.');
      return false;
    }

    try {
      final secretKey = await _getSecretKey();
      final iv        = List<int>.generate(12, (_) => Random.secure().nextInt(256));
      final secretBox = await _aes.encrypt(
        utf8.encode(senhaPlain),
        secretKey: secretKey,
        nonce: iv,
      );

      final senha = SenhaModel(
        userID:     userID,
        titulo:     titulo,
        usuario:    usuario,
        cipherText: base64Encode(secretBox.cipherText),
        authTag:    base64Encode(secretBox.mac.bytes),
        iv:         base64Encode(secretBox.nonce),
        tipo:       tipo,
        url:        url,
        favorito:   favorito,
        imagemPath: imagemPath,
      );

      final id = await DbService.db.insert('senhas', senha.toMap()..remove('id'));
      debugPrint('Senha salva com id: $id');
      return true;

    } catch (e) {
      debugPrint('Erro ao salvar senha: $e');
      return false;
    }
  }

  static Future<bool> editar({
    required int    id,
    required String titulo,
    required String usuario,
    required String senhaPlain,
    required String tipo,
    String url = '',
    String? imagemPath,
  }) async {
    if (titulo.trim().isEmpty || senhaPlain.isEmpty) {
      debugPrint('Título e senha são obrigatórios.');
      return false;
    }

    try {
      final secretKey = await _getSecretKey();
      final iv        = List<int>.generate(12, (_) => Random.secure().nextInt(256));
      final secretBox = await _aes.encrypt(
        utf8.encode(senhaPlain),
        secretKey: secretKey,
        nonce: iv,
      );

      final valores = {
        'titulo':     titulo,
        'usuario':    usuario,
        'cipherText': base64Encode(secretBox.cipherText),
        'authTag':    base64Encode(secretBox.mac.bytes),
        'IV':         base64Encode(secretBox.nonce),
        'tipo':       tipo,
        'url':        url,
      };

      if (imagemPath != null) {
        valores['imagemPath'] = imagemPath;
      }

      final updated = await DbService.db.update(
        'senhas',
        valores,
        where:     'id = ?',
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

  static Future<List<Map<String, dynamic>>> buscarTodas(int userID) async {
    try {
      final rows      = await DbService.db.query('senhas', where: 'userID = ?', whereArgs: [userID]);
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

  static Future<Map<String, dynamic>?> buscarPorId(int id) async {
    try {
      final rows = await DbService.db.query('senhas', where: 'id = ?', whereArgs: [id], limit: 1);
      if (rows.isEmpty) return null;
      final secretKey = await _getSecretKey();
      return await _decriptar(rows.first, secretKey);

    } catch (e) {
      debugPrint('Erro ao buscar senha por id: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> _decriptar(
    Map<String, dynamic> row,
    SecretKey secretKey,
  ) async {
    try {
      final secretBox = SecretBox(
        base64Decode(row['cipherText'] as String),
        nonce: base64Decode(row['IV']      as String),
        mac:   Mac(base64Decode(row['authTag'] as String)),
      );

      final plainBytes = await _aes.decrypt(secretBox, secretKey: secretKey);

      return {
        'id':         row['id'],
        'userID':     row['userID'],
        'titulo':     row['titulo'],
        'usuario':    row['usuario'],
        'senha':      utf8.decode(plainBytes),
        'tipo':       row['tipo'],
        'url':        row['url'] ?? '',
        'favorito':   (row['favorito'] as int? ?? 0),
        'imagemPath': row['imagemPath'],
      };

    } catch (e) {
      debugPrint('Falha ao decriptar entrada id ${row['id']}: $e');
      return null;
    }
  }

  static Future<bool> favoritar(int id, {required bool favorito}) async {
    final updated = await DbService.db.update(
      'senhas',
      {'favorito': favorito ? 1 : 0},
      where:     'id = ?',
      whereArgs: [id],
    );
    return updated > 0;
  }

  static Future<int> buscarFavorito(int id) async {
    final rows = await DbService.db.query(
      'senhas',
      columns:   ['favorito'],
      where:     'id = ?',
      whereArgs: [id],
    );
    if (rows.isEmpty) return 0;
    return (rows.first['favorito'] as int? ?? 0);
  }

  static Future<bool> deletar(int id) async {
    try {
      final deleted = await DbService.db.delete('senhas', where: 'id = ?', whereArgs: [id]);
      return deleted > 0;
    } catch (e) {
      debugPrint('Erro ao deletar senha: $e');
      return false;
    }
  }
}