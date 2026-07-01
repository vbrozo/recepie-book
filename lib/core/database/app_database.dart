import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'migrations/migration_v1.dart';

/// Opens (and lazily creates) the app's single SQLite database.
class AppDatabase {
  AppDatabase._();

  static const _dbName = 'recipe_book.db';
  static const _dbVersion = 1;

  static Database? _database;

  static Future<Database> get instance async {
    return _database ??= await _open();
  }

  static Future<Database> _open() async {
    final path = join(await getDatabasesPath(), _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async {
        for (final statement in migrationV1) {
          await db.execute(statement);
        }
      },
    );
  }
}
