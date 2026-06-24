import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:path/path.dart';

class DbService {
  static Database? _db;

  static Future<void> init(String dbKey) async {
    if (_db != null && _db!.isOpen) return;

    final path = join(await getDatabasesPath(), 'krypton.db');
    _db = await openDatabase(
      path,
      password: dbKey,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            id    INTEGER PRIMARY KEY AUTOINCREMENT,
            nome  TEXT NOT NULL
          );
        ''');
        await db.execute('''
          CREATE TABLE senhas (
            id         INTEGER PRIMARY KEY AUTOINCREMENT,
            userID     INTEGER NOT NULL,
            titulo     TEXT    NOT NULL,
            usuario    TEXT    NOT NULL,
            cipherText TEXT    NOT NULL,
            authTag    TEXT    NOT NULL,
            IV         TEXT    NOT NULL UNIQUE,
            tipo       TEXT    NOT NULL,
            url        TEXT,
            favorito   INTEGER NOT NULL,
            FOREIGN KEY (userID) REFERENCES users(id) ON DELETE CASCADE
          );
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE senhas ADD COLUMN url TEXT;');
        }
      },
      version: 2,
    );
  }

  static Future<bool> userRegistered() async {
    if (_db == null) return false;

    // Executa uma query que conta o número de registros na tabela 'usuarios'
    final List<Map<String, dynamic>> resultado = await db.rawQuery(
      'SELECT COUNT(*) as total FROM usuarios'
    );

    // Obtém a quantidade de registros
    int? total = resultado.first['total'] as int?;

    // Retorna true se já houver 1 ou mais usuários
    return total! > 0;
  }

  static Database get db {
    if (_db == null || !_db!.isOpen) {
      throw StateError('DbService não inicializado. Chame init() primeiro.');
    }
    return _db!;
  }

  static Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  static bool get isOpen => _db != null && _db!.isOpen;
}