import 'package:path/path.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:krypton/services/keystore_services.dart';

Future<Database> createDatabase() async {
  try {
    String? dbKey = await KeystoreService.createDbKey();

    final String databasePath = join(await getDatabasesPath(), 'krypton.db');

    return openDatabase(
      databasePath,
      password: dbKey,
      onCreate: (db, version) {
        db.execute(
          'CREATE TABLE senhas (id INTEGER PRIMARY KEY AUTOINCREMENT, cipherText TEXT, authTag TEXT, IV TEXT UNIQUE, titulo TEXT, usuario TEXT);',
        );
      },
      version: 1,
    );

  } catch (e) {
    throw Exception(e.toString());
  }  
}