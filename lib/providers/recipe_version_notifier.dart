import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/recipe_with_details.dart';
import '../repositories/recipe_version_repository.dart';
import 'recipe_version_state.dart';

/// Owns the version history for a single recipe (see [recipeVersionsProvider],
/// which is `.family`-scoped by recipe id).
class RecipeVersionNotifier extends StateNotifier<RecipeVersionState> {
  RecipeVersionNotifier(this._repository, this.recipeId) : super(const RecipeVersionState());

  final RecipeVersionRepository _repository;
  final String recipeId;

  Future<void> loadVersions() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final versions = await _repository.getVersionsForRecipe(recipeId);
      state = state.copyWith(versions: versions, isLoading: false);
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
    }
  }

  Future<void> createVersion({required RecipeWithDetails recipe, String? note}) async {
    try {
      await _repository.createVersion(recipe: recipe, note: note);
      await loadVersions();
    } catch (error) {
      state = state.copyWith(errorMessage: error.toString());
    }
  }
}
