import 'package:flutter/foundation.dart';
import '../database/db.dart';
import '../models/user.dart';
import '../../services/keystore_services.dart';

class UserController {

  // Cadastro: gera as chaves, abre o banco e insere o usuário
  static Future<bool> cadastrar({
    required String nome,
    required String email,
    required String senhaMestre,
  }) async {
    if (nome.trim().isEmpty || email.trim().isEmpty || senhaMestre.isEmpty) {
      debugPrint('Campos obrigatórios não preenchidos.');
      return false;
    }

    try {
      // Gera DB_Key, blobs, salts e abre o banco (DbService.init é chamado internamente)
      await KeystoreService.registerDbKey(senhaMestre, email);

      final db   = DbService.db;
      final user = User(nome: nome, email: email);

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