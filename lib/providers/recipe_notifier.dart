import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ingredient.dart';
import '../models/recipe.dart';
import '../models/recipe_image.dart';
import '../models/recipe_step.dart';
import '../repositories/recipe_repository.dart';
import 'recipe_state.dart';

/// Owns [RecipeState] and drives it through [RecipeRepository].
///
/// All mutating methods (create/update/delete/toggleFavorite) re-run the
/// current query (plain list or active search) afterwards so the state
/// always reflects what's in the database.
class RecipeNotifier extends StateNotifier<RecipeState> {
  RecipeNotifier(this._repository) : super(const RecipeState());

  final RecipeRepository _repository;

  Future<void> loadRecipes() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final recipes = await _repository.getAllRecipes();
      state = state.copyWith(
        recipes: recipes,
        isLoading: false,
        searchQuery: '',
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
    }
  }

  Future<void> createRecipe({
    required Recipe recipe,
    List<Ingredient> ingredients = const [],
    List<RecipeStep> steps = const [],
    List<RecipeImage> images = const [],
    List<String> tagIds = const [],
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.createRecipe(
        recipe: recipe,
        ingredients: ingredients,
        steps: steps,
        images: images,
        tagIds: tagIds,
      );
      await _refresh();
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
    }
  }

  Future<void> updateRecipe({
    required Recipe recipe,
    List<Ingredient> ingredients = const [],
    List<RecipeStep> steps = const [],
    List<RecipeImage> images = const [],
    List<String> tagIds = const [],
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.updateRecipe(
        recipe: recipe,
        ingredients: ingredients,
        steps: steps,
        images: images,
        tagIds: tagIds,
      );
      await _refresh();
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
    }
  }

  /// Deletes the recipe and returns the image file paths it owned, so the
  /// caller can remove them from disk (the repository/database do not touch
  /// the filesystem).
  Future<List<String>> deleteRecipe(String id) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final imagePaths = await _repository.deleteRecipe(id);
      await _refresh();
      return imagePaths;
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
      return const [];
    }
  }

  Future<void> searchRecipes(String query) async {
    final trimmed = query.trim();
    state = state.copyWith(isLoading: true, errorMessage: null, searchQuery: trimmed);
    try {
      final recipes = trimmed.isEmpty
          ? await _repository.getAllRecipes()
          : await _repository.searchRecipes(trimmed);
      state = state.copyWith(recipes: recipes, isLoading: false);
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
    }
  }

  /// Flips favorite status and optimistically updates the in-memory list so
  /// the UI reacts instantly, without waiting on a full reload.
  Future<void> toggleFavorite(String id) async {
    final index = state.recipes.indexWhere((r) => r.recipe.id == id);
    if (index == -1) return;

    final previousRecipes = state.recipes;
    final target = previousRecipes[index];
    final optimistic = target.copyWith(
      recipe: target.recipe.copyWith(isFavorite: !target.recipe.isFavorite),
    );
    final optimisticRecipes = [...previousRecipes]..[index] = optimistic;
    state = state.copyWith(recipes: optimisticRecipes, errorMessage: null);

    try {
      await _repository.toggleFavorite(id);
    } catch (error) {
      // Roll back on failure.
      state = state.copyWith(recipes: previousRecipes, errorMessage: error.toString());
    }
  }

  void setFavoritesOnly(bool value) {
    state = state.copyWith(favoritesOnly: value);
  }

  void setTagFilter(String? tagId) {
    state = tagId == null
        ? state.copyWith(clearTagFilter: true)
        : state.copyWith(tagFilterId: tagId);
  }

  void setMaxPrepTime(int? minutes) {
    state = minutes == null
        ? state.copyWith(clearMaxPrepTime: true)
        : state.copyWith(maxPrepTimeMinutes: minutes);
  }

  void clearFilters() {
    state = state.copyWith(
      favoritesOnly: false,
      clearTagFilter: true,
      clearMaxPrepTime: true,
    );
  }

  Future<void> _refresh() {
    return state.isSearching
        ? searchRecipes(state.searchQuery)
        : loadRecipes();
  }
}
