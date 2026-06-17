import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:path/path.dart';

class DbService {
  static Database? _db;

  // Abre o banco (ou retorna a instância já aberta)
  static Future<void> init(String dbKey) async {
    if (_db != null && _db!.isOpen) return ;

    final path = join(await getDatabasesPath(), 'krypton.db');
    _db = await openDatabase(
      path,
      password: dbKey,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            nome        TEXT NOT NULL,
            email       TEXT NOT NULL UNIQUE,
            senhaMestre TEXT NOT NULL,
            senhaRecup  TEXT NOT NULL
          );
        ''');
        await db.execute('''
          CREATE TABLE senhas (
            id         INTEGER PRIMARY KEY AUTOINCREMENT,
            userID     INTEGER NOT NULL,
            titulo     TEXT NOT NULL,
            usuario    TEXT NOT NULL,
            cipherText TEXT NOT NULL,
            authTag    TEXT NOT NULL,
            IV         TEXT NOT NULL UNIQUE,
            FOREIGN KEY (userID) REFERENCES users(id) ON DELETE CASCADE
          );
        ''');
      },
      version: 1,
    );
  }

  // Chama em qualquer lugar sem precisar de dbKey (só funciona se já estiver com o banco aberto)
  static Database get db {
    if (_db == null || !_db!.isOpen) throw StateError('DbService não inicializado. Chame init() primeiro.');
    return _db!;
  }

  // fecha o banco no logout ou quando fecha o app
  static Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  static bool get isOpen => _db != null && _db!.isOpen;
}