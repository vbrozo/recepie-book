import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:recepie_book/core/database/database_helper.dart';

/// Points sqflite's global `databaseFactory` at `sqflite_common_ffi` (a real
/// SQLite running on the Dart VM) so repository tests can run under `flutter
/// test` / `dart test` without a device or browser. Safe to call more than
/// once — `sqfliteFfiInit()` just re-registers the same native bindings.
void initTestDatabaseFactory() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}

/// A fresh, isolated in-memory database for a single test — use in `setUp`
/// so nothing persists (or leaks) between test cases.
DatabaseHelper newTestDatabaseHelper() => DatabaseHelper.testing();
