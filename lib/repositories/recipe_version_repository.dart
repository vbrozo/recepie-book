import 'package:uuid/uuid.dart';

import '../core/database/database_helper.dart';
import '../models/recipe_snapshot.dart';
import '../models/recipe_version.dart';
import '../models/recipe_with_details.dart';

const _uuid = Uuid();

/// Read/write access to `recipe_versions`. Restoring a version back onto
/// the live recipe is *not* done here — that goes through
/// [RecipeRepository.updateRecipe] (via `RecipeNotifier`) so the recipe
/// list's cached state stays in sync; see RecipeVersionsScreen.
class RecipeVersionRepository {
  RecipeVersionRepository({DatabaseHelper? databaseHelper})
      : _dbHelper = databaseHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _dbHelper;

  /// Version history is capped per recipe — old snapshots are pruned as
  /// soon as this is exceeded (see [createVersion]) so a long-lived recipe
  /// doesn't accumulate an ever-growing `recipe_versions` table. Images
  /// aren't affected either way: a version's snapshot never stores images
  /// (see RecipeSnapshot) — restoring an old version keeps whatever images
  /// the recipe currently has, so pruning old versions can't touch them.
  static const maxVersionsPerRecipe = 10;

  Future<List<RecipeVersion>> getVersionsForRecipe(String recipeId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'recipe_versions',
      where: 'recipe_id = ?',
      whereArgs: [recipeId],
      orderBy: 'version_number DESC',
    );
    return maps.map(RecipeVersion.fromMap).toList();
  }

  /// Snapshots [recipe]'s current content (fields, ingredients, steps,
  /// tags) as the next version number for that recipe.
  Future<RecipeVersion> createVersion({
    required RecipeWithDetails recipe,
    String? note,
  }) async {
    final db = await _dbHelper.database;

    return db.transaction((txn) async {
      final maxRows = await txn.rawQuery(
        'SELECT MAX(version_number) AS max_version FROM recipe_versions WHERE recipe_id = ?',
        [recipe.recipe.id],
      );
      final currentMax = maxRows.first['max_version'] as int?;

      final version = RecipeVersion(
        id: _uuid.v4(),
        recipeId: recipe.recipe.id,
        versionNumber: (currentMax ?? 0) + 1,
        note: (note == null || note.trim().isEmpty) ? null : note.trim(),
        snapshotJson: RecipeSnapshot.encode(
          recipe: recipe.recipe,
          ingredients: recipe.ingredients,
          steps: recipe.steps,
          tags: recipe.tags,
        ),
        createdAt: DateTime.now(),
      );

      await txn.insert('recipe_versions', version.toMap());

      // Keep only the most recent [maxVersionsPerRecipe] rows for this
      // recipe. Version numbers themselves keep incrementing forever
      // (unaffected by what gets pruned) — only how many old rows we keep
      // around is capped.
      await txn.rawDelete(
        '''
        DELETE FROM recipe_versions
        WHERE recipe_id = ?
          AND id NOT IN (
            SELECT id FROM recipe_versions
            WHERE recipe_id = ?
            ORDER BY version_number DESC
            LIMIT ?
          )
        ''',
        [recipe.recipe.id, recipe.recipe.id, maxVersionsPerRecipe],
      );

      return version;
    });
  }
}
