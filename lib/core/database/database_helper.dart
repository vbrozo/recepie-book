import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'migrations/migration_v1.dart';

/// Singleton owning the app's single SQLite connection.
class DatabaseHelper {
  DatabaseHelper._internal();

  static final DatabaseHelper instance = DatabaseHelper._internal();

  static const String _dbName = 'recipes_app.db';
  static const int _dbVersion = 1;

  Database? _database;

  Future<Database> get database async {
    return _database ??= await _initDatabase();
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    for (final statement in migrationV1) {
      await db.execute(statement);
    }
  }

  /// Applies migrations in order as the schema evolves. Each future bump
  /// adds a `migration_vN.dart` file and an `if (oldVersion < N)` block
  /// here, e.g.:
  ///
  /// ```dart
  /// if (oldVersion < 2) {
  ///   for (final statement in migrationV2) {
  ///     await db.execute(statement);
  ///   }
  /// }
  /// ```
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {}

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
