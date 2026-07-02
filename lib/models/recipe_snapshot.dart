import 'dart:convert';

import 'ingredient.dart';
import 'recipe.dart';
import 'recipe_step.dart';
import 'recipe_version.dart';
import 'tag.dart';

/// The recipe content captured by a [RecipeVersion]'s `snapshot_json`:
/// the recipe's own fields, its ingredients, its steps and its tags.
/// Images aren't versioned (see ARCHITECTURE.md §5 — they're files, not
/// content), so a restore keeps whatever images the recipe currently has.
class RecipeSnapshot {
  const RecipeSnapshot({
    required this.recipe,
    required this.ingredients,
    required this.steps,
    required this.tags,
  });

  final Recipe recipe;
  final List<Ingredient> ingredients;
  final List<RecipeStep> steps;
  final List<Tag> tags;

  List<String> get tagIds => tags.map((tag) => tag.id).toList();

  factory RecipeSnapshot.fromVersion(RecipeVersion version) {
    final data = json.decode(version.snapshotJson) as Map<String, dynamic>;
    return RecipeSnapshot(
      recipe: Recipe.fromJson(data['recipe'] as Map<String, dynamic>),
      ingredients: (data['ingredients'] as List)
          .cast<Map<String, dynamic>>()
          .map(Ingredient.fromJson)
          .toList(),
      steps: (data['steps'] as List)
          .cast<Map<String, dynamic>>()
          .map(RecipeStep.fromJson)
          .toList(),
      tags: (data['tags'] as List)
          .cast<Map<String, dynamic>>()
          .map(Tag.fromJson)
          .toList(),
    );
  }

  /// Serializes into the JSON string stored as `recipe_versions.snapshot_json`.
  static String encode({
    required Recipe recipe,
    required List<Ingredient> ingredients,
    required List<RecipeStep> steps,
    required List<Tag> tags,
  }) {
    return json.encode({
      'recipe': recipe.toJson(),
      'ingredients': ingredients.map((i) => i.toJson()).toList(),
      'steps': steps.map((s) => s.toJson()).toList(),
      'tags': tags.map((t) => t.toJson()).toList(),
    });
  }
}
