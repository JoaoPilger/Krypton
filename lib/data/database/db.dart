import 'package:drift/drift.dart';
import 'package:krypton/data/database/app_database.dart';

class RawDb {
  final QueryExecutor _exec;
  RawDb(this._exec);

  Future<int> insert(String table, Map<String, Object?> values) async {
    final map  = Map<String, Object?>.from(values)..remove('id');
    final cols = map.keys.join(', ');
    final ph   = map.keys.map((_) => '?').join(', ');
    final args = map.values.map(_toArg).toList();
    return await _exec.runInsert(
      'INSERT INTO "$table" ($cols) VALUES ($ph)', args,
    );
  }

  Future<List<Map<String, Object?>>> query(
    String table, {
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    int? limit,
  }) async {
    final cols = columns?.join(', ') ?? '*';
    final wh   = where != null ? 'WHERE $where' : '';
    final lim  = limit != null ? 'LIMIT $limit' : '';
    return await _exec.runSelect(
      'SELECT $cols FROM "$table" $wh $lim',
      (whereArgs ?? []).map(_toArg).toList(),
    );
  }

  Future<List<Map<String, Object?>>> rawQuery(
    String sql, [List<Object?>? args]
  ) async {
    return await _exec.runSelect(sql, (args ?? []).map(_toArg).toList());
  }

  Future<int> update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final set  = values.keys.map((k) => '"$k" = ?').join(', ');
    final wh   = where != null ? 'WHERE $where' : '';
    final args = [...values.values.map(_toArg), ...(whereArgs ?? []).map(_toArg)];
    return await _exec.runUpdate(
      'UPDATE "$table" SET $set $wh', args,
    );
  }

  Future<int> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final wh   = where != null ? 'WHERE $where' : '';
    final args = (whereArgs ?? []).map(_toArg).toList();
    return await _exec.runDelete(
      'DELETE FROM "$table" $wh', args,
    );
  }

  Object? _toArg(Object? v) => v is bool ? (v ? 1 : 0) : v;
}

class DbService {
  static AppDatabase? _instance;

  static Future<void> init(String dbKey) async {
    if (_instance != null) return;
    _instance = await AppDatabase.open(dbKey);
  }

  static RawDb get db {
    if (_instance == null) {
      throw StateError('DbService não inicializado. Chame init() primeiro.');
    }
    return RawDb(_instance!.executor);
  }

  static Future<void> close() async {
    await _instance?.close();
    _instance = null;
  }

  static Future<bool> userRegistered() async {
    if (_instance == null) return false;
    return await _instance!.userRegistered();
  }
}