import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'migrations/migration_v1.dart';

/// Singleton owning the app's single SQLite connection.
///
/// On web, sqflite has no built-in implementation, so this routes through
/// sqflite_common_ffi_web (a real SQLite compiled to wasm, not an
/// IndexedDB emulation — PRAGMA/foreign keys and the rest of migration_v1
/// work unmodified). The wasm binary is intentionally loaded from its
/// upstream GitHub release at runtime rather than vendored under web/,
/// because this repo's build environment can't reach GitHub release
/// assets to download it; an end user's browser loading the deployed
/// GitHub Pages site has no such restriction. The matching shared-worker
/// script (sqflite_sw.js) *is* vendored under web/, compiled locally with
/// `dart compile js`.
class DatabaseHelper {
  DatabaseHelper._internal();

  static final DatabaseHelper instance = DatabaseHelper._internal();

  static const String _dbName = 'recipes_app.db';
  static const int _dbVersion = 1;

  /// Same release sqflite_common_ffi_web's own `setup` tool pins by
  /// default (see sqlite3_wasm_version.dart in that package).
  static final Uri _webSqlite3WasmUri = Uri.parse(
    'https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-3.1.2/sqlite3.wasm',
  );

  Database? _database;
  bool _webFactoryConfigured = false;

  Future<Database> get database async {
    return _database ??= await _initDatabase();
  }

  Future<Database> _initDatabase() async {
    if (kIsWeb) {
      _ensureWebFactory();
      // The web factory keys databases by name in IndexedDB — no
      // filesystem path to resolve, unlike native platforms.
      return openDatabase(
        _dbName,
        version: _dbVersion,
        onConfigure: _onConfigure,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    }

    final path = join(await getDatabasesPath(), _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  void _ensureWebFactory() {
    if (_webFactoryConfigured) return;
    _webFactoryConfigured = true;
    databaseFactory = createDatabaseFactoryFfiWeb(
      options: SqfliteFfiWebOptions(sqlite3WasmUri: _webSqlite3WasmUri),
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
