import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class AppDatabase {
  final DatabaseConnection _conn;

  AppDatabase._(this._conn);

  static Future<AppDatabase> open(String dbKeyB64) async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file     = File(p.join(dbFolder.path, 'krypton.db'));
    final hex      = _b64UrlToHex(dbKeyB64);

    // NativeDatabase síncrono — abre imediatamente, sem lazy
    final executor = NativeDatabase(
      file,
      setup: (rawDb) {
        rawDb.execute("PRAGMA key = \"x'$hex';\";");
      },
    );

    // Força abertura real antes de qualquer uso
    final conn = DatabaseConnection(executor);
    await executor.ensureOpen(_KryptonUser());

    final db = AppDatabase._(conn);
    await db._init(executor);
    return db;
  }

  Future<void> _init(QueryExecutor executor) async {
    await executor.runCustom('PRAGMA foreign_keys = ON;', []);
    await executor.runCustom('''
      CREATE TABLE IF NOT EXISTS users (
        id    INTEGER PRIMARY KEY AUTOINCREMENT,
        nome  TEXT NOT NULL
      );
    ''', []);
    await executor.runCustom('''
      CREATE TABLE IF NOT EXISTS senhas (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        userID     INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        titulo     TEXT    NOT NULL,
        usuario    TEXT    NOT NULL,
        cipherText TEXT    NOT NULL,
        authTag    TEXT    NOT NULL,
        IV         TEXT    NOT NULL UNIQUE,
        tipo       TEXT    NOT NULL,
        url        TEXT,
        favorito   INTEGER NOT NULL DEFAULT 0
      );
    ''', []);
  }

  Future<bool> userRegistered() async {
    final rows = await _conn.executor.runSelect(
      'SELECT COUNT(*) as total FROM users', [],
    );
    return (rows.first['total'] as int? ?? 0) > 0;
  }

  QueryExecutor get executor => _conn.executor;

  Future<void> close() async => await _conn.executor.close();
}

// Necessário para executor.ensureOpen()
class _KryptonUser extends QueryExecutorUser {
  @override
  Future<void> beforeOpen(QueryExecutor executor, OpeningDetails details) async {}

  @override
  int get schemaVersion => 1;
}

String _b64UrlToHex(String b64url) {
  final normalized = b64url.replaceAll('-', '+').replaceAll('_', '/');
  final padded = normalized.padRight(
    normalized.length + (4 - normalized.length % 4) % 4, '=',
  );
  final bytes = base64Decode(padded);
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}