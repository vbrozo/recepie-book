import 'package:sqflite/sqflite.dart';

import '../core/database/database_helper.dart';
import '../models/ingredient.dart';
import '../models/recipe.dart';
import '../models/recipe_image.dart';
import '../models/recipe_step.dart';
import '../models/recipe_with_details.dart';
import '../models/tag.dart';

/// CRUD + search access to recipes and everything attached to them
/// (ingredients, steps, images, tags).
class RecipeRepository {
  RecipeRepository({DatabaseHelper? databaseHelper})
      : _dbHelper = databaseHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _dbHelper;

  /// Inserts a recipe and all of its children in a single transaction.
  /// [tagIds] must reference already-existing rows in `tags`.
  Future<void> createRecipe({
    required Recipe recipe,
    List<Ingredient> ingredients = const [],
    List<RecipeStep> steps = const [],
    List<RecipeImage> images = const [],
    List<String> tagIds = const [],
  }) async {
    final db = await _dbHelper.database;

    await db.transaction((txn) async {
      await txn.insert('recipes', recipe.toMap());
      await _insertChildren(
        txn,
        recipeId: recipe.id,
        ingredients: ingredients,
        steps: steps,
        images: images,
        tagIds: tagIds,
      );
    });
  }

  Future<List<RecipeWithDetails>> getAllRecipes() async {
    final db = await _dbHelper.database;
    final recipeMaps = await db.query(
      'recipes',
      orderBy: 'title COLLATE NOCASE ASC',
    );

    return _loadDetailsBatch(db, recipeMaps.map(Recipe.fromMap).toList());
  }

  Future<RecipeWithDetails?> getRecipeById(String id) async {
    final db = await _dbHelper.database;
    final recipeMaps = await db.query(
      'recipes',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (recipeMaps.isEmpty) return null;
    return _loadDetails(db, Recipe.fromMap(recipeMaps.first));
  }

  /// Replaces the recipe row and wholesale-replaces its children
  /// (ingredients/steps/images/tags) with the given lists, in a single
  /// transaction. Simpler and safer than diffing individual rows for a
  /// form-based edit screen.
  Future<void> updateRecipe({
    required Recipe recipe,
    List<Ingredient> ingredients = const [],
    List<RecipeStep> steps = const [],
    List<RecipeImage> images = const [],
    List<String> tagIds = const [],
  }) async {
    final db = await _dbHelper.database;

    await db.transaction((txn) async {
      final updated = recipe.copyWith(updatedAt: DateTime.now());
      await txn.update(
        'recipes',
        updated.toMap(),
        where: 'id = ?',
        whereArgs: [recipe.id],
      );

      await txn.delete('ingredients', where: 'recipe_id = ?', whereArgs: [recipe.id]);
      await txn.delete('recipe_steps', where: 'recipe_id = ?', whereArgs: [recipe.id]);
      await txn.delete('recipe_images', where: 'recipe_id = ?', whereArgs: [recipe.id]);
      await txn.delete('recipe_tags', where: 'recipe_id = ?', whereArgs: [recipe.id]);

      await _insertChildren(
        txn,
        recipeId: recipe.id,
        ingredients: ingredients,
        steps: steps,
        images: images,
        tagIds: tagIds,
      );
    });
  }

  /// Deletes the recipe (children cascade via foreign keys). Returns the
  /// file paths of the images that belonged to it so the caller can remove
  /// the physical files from disk — the database only owns the rows, not
  /// the files (see ARCHITECTURE.md §5).
  Future<List<String>> deleteRecipe(String id) async {
    final db = await _dbHelper.database;

    final imageMaps = await db.query(
      'recipe_images',
      columns: ['file_path'],
      where: 'recipe_id = ?',
      whereArgs: [id],
    );

    await db.delete('recipes', where: 'id = ?', whereArgs: [id]);

    return imageMaps.map((map) => map['file_path'] as String).toList();
  }

  Future<List<RecipeWithDetails>> searchRecipes(String query) async {
    final db = await _dbHelper.database;
    final likeQuery = '%$query%';

    final recipeMaps = await db.query(
      'recipes',
      where: 'title LIKE ? OR description LIKE ?',
      whereArgs: [likeQuery, likeQuery],
      orderBy: 'title COLLATE NOCASE ASC',
    );

    return _loadDetailsBatch(db, recipeMaps.map(Recipe.fromMap).toList());
  }

  /// Atomically flips `is_favorite` without a separate read.
  Future<void> toggleFavorite(String id) async {
    final db = await _dbHelper.database;

    await db.rawUpdate(
      '''
      UPDATE recipes
      SET is_favorite = CASE WHEN is_favorite = 1 THEN 0 ELSE 1 END,
          updated_at = ?
      WHERE id = ?
      ''',
      [DateTime.now().toIso8601String(), id],
    );
  }

  Future<void> _insertChildren(
    DatabaseExecutor txn, {
    required String recipeId,
    required List<Ingredient> ingredients,
    required List<RecipeStep> steps,
    required List<RecipeImage> images,
    required List<String> tagIds,
  }) async {
    for (final ingredient in ingredients) {
      await txn.insert('ingredients', ingredient.toMap());
    }
    for (final step in steps) {
      await txn.insert('recipe_steps', step.toMap());
    }
    for (final image in images) {
      await txn.insert('recipe_images', image.toMap());
    }
    for (final tagId in tagIds) {
      await txn.insert('recipe_tags', {
        'recipe_id': recipeId,
        'tag_id': tagId,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }

  /// SQLite caps the number of bound parameters per statement (historically
  /// 999); chunking keeps `_loadDetailsBatch` correct even for very large
  /// recipe collections instead of failing once someone has 1000+ recipes.
  static const _maxSqliteVariables = 900;

  /// Loads children for many recipes at once (4 batch queries total,
  /// regardless of recipe count) instead of one round-trip per recipe —
  /// [_loadDetails] alone would mean 4N queries for a list of N recipes.
  Future<List<RecipeWithDetails>> _loadDetailsBatch(
    DatabaseExecutor db,
    List<Recipe> recipes,
  ) async {
    if (recipes.isEmpty) return const [];
    if (recipes.length == 1) {
      return [await _loadDetails(db, recipes.first)];
    }

    final ingredientsByRecipe = <String, List<Ingredient>>{};
    final stepsByRecipe = <String, List<RecipeStep>>{};
    final imagesByRecipe = <String, List<RecipeImage>>{};
    final tagsByRecipe = <String, List<Tag>>{};

    for (var offset = 0; offset < recipes.length; offset += _maxSqliteVariables) {
      final chunk = recipes.skip(offset).take(_maxSqliteVariables);
      final recipeIds = chunk.map((r) => r.id).toList();
      final placeholders = List.filled(recipeIds.length, '?').join(',');

      final ingredientMaps = await db.query(
        'ingredients',
        where: 'recipe_id IN ($placeholders)',
        whereArgs: recipeIds,
        orderBy: 'sort_order ASC',
      );
      final stepMaps = await db.query(
        'recipe_steps',
        where: 'recipe_id IN ($placeholders)',
        whereArgs: recipeIds,
        orderBy: 'step_number ASC',
      );
      final imageMaps = await db.query(
        'recipe_images',
        where: 'recipe_id IN ($placeholders)',
        whereArgs: recipeIds,
        orderBy: 'sort_order ASC',
      );
      final tagRows = await db.rawQuery(
        '''
        SELECT tags.*, recipe_tags.recipe_id AS recipe_id
        FROM tags
        INNER JOIN recipe_tags ON recipe_tags.tag_id = tags.id
        WHERE recipe_tags.recipe_id IN ($placeholders)
        ORDER BY tags.name COLLATE NOCASE ASC
        ''',
        recipeIds,
      );

      ingredientsByRecipe.addAll(_groupByRecipeId(ingredientMaps, Ingredient.fromMap));
      stepsByRecipe.addAll(_groupByRecipeId(stepMaps, RecipeStep.fromMap));
      imagesByRecipe.addAll(_groupByRecipeId(imageMaps, RecipeImage.fromMap));
      tagsByRecipe.addAll(_groupByRecipeId(tagRows, Tag.fromMap));
    }

    return recipes
        .map((recipe) => RecipeWithDetails(
              recipe: recipe,
              ingredients: ingredientsByRecipe[recipe.id] ?? const [],
              steps: stepsByRecipe[recipe.id] ?? const [],
              images: imagesByRecipe[recipe.id] ?? const [],
              tags: tagsByRecipe[recipe.id] ?? const [],
            ))
        .toList();
  }

  /// Groups flat query rows (each carrying a `recipe_id` column) back into
  /// per-recipe lists, preserving row order within each group.
  Map<String, List<T>> _groupByRecipeId<T>(
    List<Map<String, Object?>> rows,
    T Function(Map<String, Object?>) fromMap,
  ) {
    final result = <String, List<T>>{};
    for (final row in rows) {
      final recipeId = row['recipe_id'] as String;
      (result[recipeId] ??= []).add(fromMap(row));
    }
    return result;
  }

  Future<RecipeWithDetails> _loadDetails(
    DatabaseExecutor db,
    Recipe recipe,
  ) async {
    final ingredientMaps = await db.query(
      'ingredients',
      where: 'recipe_id = ?',
      whereArgs: [recipe.id],
      orderBy: 'sort_order ASC',
    );
    final stepMaps = await db.query(
      'recipe_steps',
      where: 'recipe_id = ?',
      whereArgs: [recipe.id],
      orderBy: 'step_number ASC',
    );
    final imageMaps = await db.query(
      'recipe_images',
      where: 'recipe_id = ?',
      whereArgs: [recipe.id],
      orderBy: 'sort_order ASC',
    );
    final tagMaps = await db.rawQuery(
      '''
      SELECT tags.*
      FROM tags
      INNER JOIN recipe_tags ON recipe_tags.tag_id = tags.id
      WHERE recipe_tags.recipe_id = ?
      ORDER BY tags.name COLLATE NOCASE ASC
      ''',
      [recipe.id],
    );

    return RecipeWithDetails(
      recipe: recipe,
      ingredients: ingredientMaps.map(Ingredient.fromMap).toList(),
      steps: stepMaps.map(RecipeStep.fromMap).toList(),
      images: imageMaps.map(RecipeImage.fromMap).toList(),
      tags: tagMaps.map(Tag.fromMap).toList(),
    );
  }
}
