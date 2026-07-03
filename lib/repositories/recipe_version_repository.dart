import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../core/database/database_helper.dart';
import '../models/ingredient.dart';
import '../models/recipe.dart';
import '../models/recipe_snapshot.dart';
import '../models/recipe_step.dart';
import '../models/recipe_version.dart';
import '../models/recipe_with_details.dart';
import '../models/tag.dart';

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
  /// tags) as the next version number for that recipe — unless it's
  /// content-identical to the latest existing version *and* [note] is
  /// empty, in which case nothing is written and `null` is returned. This
  /// is what keeps "save without actually changing anything" (fixing a
  /// typo and undoing it, or just re-opening and saving the edit form)
  /// from silently burning one of the [maxVersionsPerRecipe] slots on a
  /// version indistinguishable from the one right before it. A non-empty
  /// [note] always gets recorded as its own version even without a content
  /// change, since the note itself is the point (e.g. a restore's audit
  /// trail, or "probano, ukusno").
  Future<RecipeVersion?> createVersion({
    required RecipeWithDetails recipe,
    String? note,
  }) async {
    final db = await _dbHelper.database;
    final trimmedNote = (note == null || note.trim().isEmpty) ? null : note.trim();

    return db.transaction((txn) async {
      final latestRows = await txn.query(
        'recipe_versions',
        where: 'recipe_id = ?',
        whereArgs: [recipe.recipe.id],
        orderBy: 'version_number DESC',
        limit: 1,
      );

      if (latestRows.isNotEmpty && trimmedNote == null) {
        final latestSnapshot = RecipeSnapshot.fromVersion(RecipeVersion.fromMap(latestRows.first));
        final sameContent = _contentFingerprint(
              recipe: latestSnapshot.recipe,
              ingredients: latestSnapshot.ingredients,
              steps: latestSnapshot.steps,
              tags: latestSnapshot.tags,
            ) ==
            _contentFingerprint(
              recipe: recipe.recipe,
              ingredients: recipe.ingredients,
              steps: recipe.steps,
              tags: recipe.tags,
            );
        if (sameContent) return null;
      }

      final maxRows = await txn.rawQuery(
        'SELECT MAX(version_number) AS max_version FROM recipe_versions WHERE recipe_id = ?',
        [recipe.recipe.id],
      );
      final currentMax = maxRows.first['max_version'] as int?;

      final version = RecipeVersion(
        id: _uuid.v4(),
        recipeId: recipe.recipe.id,
        versionNumber: (currentMax ?? 0) + 1,
        note: trimmedNote,
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

  /// A JSON string capturing everything about a recipe that counts as
  /// "content" for version-diffing purposes — deliberately excludes ids,
  /// `createdAt`/`updatedAt` and `isFavorite`, none of which represent an
  /// edit worth versioning on their own. Two calls with equivalent content
  /// produce identical strings, so callers can compare with `==` instead
  /// of writing a deep-equality check for four different model types.
  String _contentFingerprint({
    required Recipe recipe,
    required List<Ingredient> ingredients,
    required List<RecipeStep> steps,
    required List<Tag> tags,
  }) {
    final tagNames = tags.map((tag) => tag.name).toList()..sort();

    return json.encode({
      'title': recipe.title,
      'description': recipe.description,
      'servings': recipe.servings,
      'prepTimeMinutes': recipe.prepTimeMinutes,
      'cookTimeMinutes': recipe.cookTimeMinutes,
      'ingredients': [
        for (final ingredient in ingredients)
          {
            'name': ingredient.name,
            'quantity': ingredient.quantity,
            'unit': ingredient.unit,
            'sortOrder': ingredient.sortOrder,
          },
      ],
      'steps': [
        for (final step in steps)
          {
            'stepNumber': step.stepNumber,
            'instruction': step.instruction,
            'durationMinutes': step.durationMinutes,
          },
      ],
      'tagNames': tagNames,
    });
  }
}
