import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'migrations/migration_v1.dart';

/// Singleton owning the app's single SQLite connection.
///
/// On web, sqflite has no built-in implementation, so this routes through
/// sqflite_common_ffi_web (a real SQLite compiled to wasm, not an
/// IndexedDB emulation — PRAGMA/foreign keys and the rest of migration_v1
/// work unmodified). Both the wasm binary (web/sqlite3.wasm) and the
/// matching shared-worker script (web/sqflite_sw.js, compiled locally with
/// `dart compile js`) are vendored locally and served same-origin — an
/// earlier version of this pointed sqlite3WasmUri at sqlite3.dart's GitHub
/// release instead, which reliably failed at runtime (surfaced as
/// "Unsupported operation: unsupported result null" — the worker silently
/// swallowing a failed cross-origin wasm fetch instead of throwing a clear
/// error), so don't reintroduce a remote URL here without testing it end
/// to end in a real browser first.
class DatabaseHelper {
  DatabaseHelper._internal({String? testDatabasePath}) : _testDatabasePath = testDatabasePath;

  static final DatabaseHelper instance = DatabaseHelper._internal();

  /// A fresh, isolated instance backed by an in-memory SQLite database
  /// (via `databaseFactory` — repository tests point it at
  /// `sqflite_common_ffi`'s `databaseFactoryFfi` in `setUpAll`). Unlike
  /// [instance], every call returns a brand new database, so tests don't
  /// leak state into one another.
  @visibleForTesting
  factory DatabaseHelper.testing() => DatabaseHelper._internal(testDatabasePath: ':memory:');

  static const String _dbName = 'recipes_app.db';
  static const int _dbVersion = 1;

  /// Non-null only for [DatabaseHelper.testing] instances — routes
  /// [_initDatabase] straight to `openDatabase(':memory:', ...)` instead of
  /// the platform-specific (native file / web wasm) paths below.
  final String? _testDatabasePath;

  Database? _database;
  bool _webFactoryConfigured = false;

  Future<Database> get database async {
    return _database ??= await _initDatabase();
  }

  Future<Database> _initDatabase() async {
    if (_testDatabasePath != null) {
      // singleInstance: false — sqflite otherwise caches one connection per
      // path across the whole process, and every test uses the same
      // ':memory:' path; without this, a second test's DatabaseHelper.testing()
      // would hand back the first test's (already schema-initialized,
      // possibly already-closed) database instead of a clean one.
      return openDatabase(
        _testDatabasePath,
        version: _dbVersion,
        onConfigure: _onConfigure,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        singleInstance: false,
      );
    }

    if (kIsWeb) {
      _ensureWebFactory();
      // The web factory keys databases by name in IndexedDB — no
      // filesystem path to resolve, unlike native platforms.
      try {
        return await openDatabase(
          _dbName,
          version: _dbVersion,
          onConfigure: _onConfigure,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        ).timeout(
          const Duration(seconds: 20),
          onTimeout: () => throw TimeoutException(
            'Timed out loading sqlite3.wasm/sqflite_sw.js',
          ),
        );
      } catch (error, stackTrace) {
        // Re-wrapped with context: the wasm/shared-worker bridge fails in
        // ways ("Uncaught Error" with no message) that are otherwise
        // impossible to distinguish from any other DB error in the UI.
        Error.throwWithStackTrace(
          Exception('Web SQLite (sqlite3.wasm via sqflite_common_ffi_web) failed to initialize: $error'),
          stackTrace,
        );
      }
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
    // No explicit options: defaults to the same-origin relative paths
    // 'sqlite3.wasm' and 'sqflite_sw.js' (resolved against <base href>),
    // both vendored under web/.
    databaseFactory = createDatabaseFactoryFfiWeb();
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
