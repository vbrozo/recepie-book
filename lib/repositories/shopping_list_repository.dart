import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../core/database/database_helper.dart';
import '../models/ingredient.dart';
import '../models/shopping_list_item.dart';

const _uuid = Uuid();

/// CRUD access to the shopping list. Adding an item (manually or from a
/// recipe's ingredients) merges into an existing, still-unchecked row that
/// has the same name and unit instead of creating a duplicate.
class ShoppingListRepository {
  ShoppingListRepository({DatabaseHelper? databaseHelper})
      : _dbHelper = databaseHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _dbHelper;

  Future<List<ShoppingListItem>> getAllItems() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'shopping_list_items',
      orderBy: 'category COLLATE NOCASE ASC, name COLLATE NOCASE ASC',
    );
    return maps.map(ShoppingListItem.fromMap).toList();
  }

  Future<void> addItem({
    required String name,
    double? quantity,
    String? unit,
    String? category,
    String? recipeId,
  }) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await _mergeOrInsert(
        txn,
        name: name,
        quantity: quantity,
        unit: unit,
        category: category,
        recipeId: recipeId,
      );
    });
  }

  /// Copies every ingredient of a recipe into the shopping list, merging
  /// with existing (unchecked) items that share the same name and unit.
  Future<void> addIngredientsFromRecipe({
    required String recipeId,
    required List<Ingredient> ingredients,
  }) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      for (final ingredient in ingredients) {
        await _mergeOrInsert(
          txn,
          name: ingredient.name,
          quantity: ingredient.quantity,
          unit: ingredient.unit,
          category: null,
          recipeId: recipeId,
        );
      }
    });
  }

  Future<void> toggleChecked(String id) async {
    final db = await _dbHelper.database;
    await db.rawUpdate(
      '''
      UPDATE shopping_list_items
      SET is_checked = CASE WHEN is_checked = 1 THEN 0 ELSE 1 END,
          updated_at = ?
      WHERE id = ?
      ''',
      [DateTime.now().toIso8601String(), id],
    );
  }

  Future<void> deleteItem(String id) async {
    final db = await _dbHelper.database;
    await db.delete('shopping_list_items', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearCompleted() async {
    final db = await _dbHelper.database;
    await db.delete('shopping_list_items', where: 'is_checked = 1');
  }

  /// Finds an unchecked row with the same (case-insensitive) name and unit
  /// and adds [quantity] to it; otherwise inserts a new row. Only merges
  /// with unchecked items so a re-added ingredient doesn't silently
  /// un-check something the user already bought.
  Future<void> _mergeOrInsert(
    DatabaseExecutor txn, {
    required String name,
    double? quantity,
    String? unit,
    String? category,
    String? recipeId,
  }) async {
    final trimmedName = name.trim();
    final unitKey = (unit == null || unit.trim().isEmpty) ? null : unit.trim();
    final now = DateTime.now();

    final existingMaps = await txn.query(
      'shopping_list_items',
      where: 'name = ? COLLATE NOCASE AND is_checked = 0 AND '
          '(unit = ? COLLATE NOCASE OR (unit IS NULL AND ? IS NULL))',
      whereArgs: [trimmedName, unitKey, unitKey],
      limit: 1,
    );

    if (existingMaps.isNotEmpty) {
      final existing = ShoppingListItem.fromMap(existingMaps.first);
      final mergedQuantity = (existing.quantity == null && quantity == null)
          ? null
          : (existing.quantity ?? 0) + (quantity ?? 0);
      await txn.update(
        'shopping_list_items',
        {
          'quantity': mergedQuantity,
          'updated_at': now.toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [existing.id],
      );
      return;
    }

    final item = ShoppingListItem(
      id: _uuid.v4(),
      name: trimmedName,
      quantity: quantity,
      unit: unitKey,
      category: category,
      recipeId: recipeId,
      createdAt: now,
      updatedAt: now,
    );
    await txn.insert('shopping_list_items', item.toMap());
  }
}
