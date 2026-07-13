import 'dart:convert';
import 'dart:math';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../database/db.dart';
import '../models/senhas.dart';

// Controlador para gerenciar as operações de banco e criptografia de senhas
class SenhaController {
  // Armazena dados no cofre criptografado do celular
  static const _storage    = FlutterSecureStorage();
  static const _dbKeyAlias = 'db_key';
  // AesGcm.with256bits - configura a criptografia AES no modo GCM com chave de 256 bits
  static final  _aes       = AesGcm.with256bits();

  // Obtém a chave de criptografia do Keystore/Secure Storage do dispositivo
  static Future<SecretKey> _getSecretKey() async {
    // _storage.read - lê o valor salvo no armazenamento seguro pela chave informada
    final dbKeyB64 = await _storage.read(key: _dbKeyAlias);
    if (dbKeyB64 == null) throw StateError('DB_Key não encontrada no Keystore.');
    // replaceAll - ajusta caracteres do base64url para base64 padrão
    final normalized = dbKeyB64.replaceAll('-', '+').replaceAll('_', '/');
    // padRight - completa o texto com '=' para ficar no tamanho correto do base64
    final padded = normalized.padRight(
      normalized.length + (4 - normalized.length % 4) % 4, '=',
    );
    // SecretKey - encapsula os bytes da chave para usar na criptografia
    // base64Decode - converte o texto base64 de volta para bytes
    return SecretKey(base64Decode(padded));
  }

  // Criptografa a senha plano usando AES-GCM e a insere no banco
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
      // Random.secure().nextInt - gera 12 bytes aleatórios seguros para o nonce (IV)
      final iv        = List<int>.generate(12, (_) => Random.secure().nextInt(256));
      // _aes.encrypt - criptografa a senha; utf8.encode converte texto em bytes antes
      // SecretBox - guarda o resultado: dado cifrado + nonce + tag de autenticação
      final secretBox = await _aes.encrypt(
        utf8.encode(senhaPlain),
        secretKey: secretKey,
        nonce: iv,
      );

      final senha = SenhaModel(
        userID:     userID,
        titulo:     titulo,
        usuario:    usuario,
        // base64Encode - converte bytes para texto base64 (safe pra salvar no banco)
        cipherText: base64Encode(secretBox.cipherText),
        // Mac - tag de autenticidade que prova que o dado não foi adulterado
        authTag:    base64Encode(secretBox.mac.bytes),
        iv:         base64Encode(secretBox.nonce),
        tipo:       tipo,
        url:        url,
        favorito:   favorito,
        imagemPath: imagemPath,
      );

      // db.insert - grava o registro novo na tabela do SQLite
      // debugPrint - imprime no console de depuração sem impactar a performance
      final id = await DbService.db.insert('senhas', senha.toMap()..remove('id'));
      debugPrint('Senha salva com id: $id');
      return true;

    } catch (e) {
      debugPrint('Erro ao salvar senha: $e');
      return false;
    }
  }

  // Criptografa a nova senha plano e atualiza as informações no banco de dados
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

      // db.update - atualiza o registro existente no banco
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

  // Retorna todas as senhas salvas de um usuário, descriptografando-as uma por uma
  static Future<List<Map<String, dynamic>>> buscarTodas(int userID) async {
    try {
      // db.query - busca os registros no banco filtrando pelo userID
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

  // Busca e descriptografa um registro de senha específico por ID
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

  // Helper interno para descriptografar os dados salvos em Base64 usando AES-GCM
  static Future<Map<String, dynamic>?> _decriptar(
    Map<String, dynamic> row,
    SecretKey secretKey,
  ) async {
    try {
      // SecretBox - monta o pacote de descifra com os dados do banco
      final secretBox = SecretBox(
        // base64Decode - converte base64 de volta para bytes
        base64Decode(row['cipherText'] as String),
        nonce: base64Decode(row['IV']      as String),
        // Mac - a tag que valida que o dado não foi corrompido
        mac:   Mac(base64Decode(row['authTag'] as String)),
      );

      // _aes.decrypt - descriptografa e retorna os bytes originais da senha
      final plainBytes = await _aes.decrypt(secretBox, secretKey: secretKey);

      return {
        'id':         row['id'],
        'userID':     row['userID'],
        'titulo':     row['titulo'],
        'usuario':    row['usuario'],
        // utf8.decode - converte os bytes descriptografados de volta para texto
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

  // Atualiza o status de favorito (0 ou 1) de um registro no banco
  static Future<bool> favoritar(int id, {required bool favorito}) async {
    final updated = await DbService.db.update(
      'senhas',
      {'favorito': favorito ? 1 : 0},
      where:     'id = ?',
      whereArgs: [id],
    );
    return updated > 0;
  }

  // Retorna se o registro correspondente ao ID está marcado como favorito ou não
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

  // Exclui um registro de senha do banco por ID
  static Future<bool> deletar(int id) async {
    try {
      // Apaga o registro do banco pelo id
      final deleted = await DbService.db.delete('senhas', where: 'id = ?', whereArgs: [id]);
      return deleted > 0;
    } catch (e) {
      debugPrint('Erro ao deletar senha: $e');
      return false;
    }
  }
}