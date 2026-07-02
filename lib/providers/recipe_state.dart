import '../models/recipe_with_details.dart';

/// UI-facing state for the recipe list/search screen.
///
/// [recipes] is whatever the last DB query returned (full list or active
/// search results). Favorite/tag/prep-time filters are applied on top of
/// that in-memory via [filteredRecipes] rather than re-querying the DB,
/// since the whole (small, personal) recipe set is already loaded with
/// full details.
class RecipeState {
  final List<RecipeWithDetails> recipes;
  final bool isLoading;
  final String? errorMessage;
  final String searchQuery;
  final bool favoritesOnly;
  final String? tagFilterId;
  final int? maxPrepTimeMinutes;

  const RecipeState({
    this.recipes = const [],
    this.isLoading = false,
    this.errorMessage,
    this.searchQuery = '',
    this.favoritesOnly = false,
    this.tagFilterId,
    this.maxPrepTimeMinutes,
  });

  bool get isSearching => searchQuery.isNotEmpty;

  bool get hasActiveFilters =>
      favoritesOnly || tagFilterId != null || maxPrepTimeMinutes != null;

  List<RecipeWithDetails> get filteredRecipes {
    if (!hasActiveFilters) return recipes;

    return recipes.where((item) {
      if (favoritesOnly && !item.recipe.isFavorite) return false;

      if (tagFilterId != null && !item.tags.any((tag) => tag.id == tagFilterId)) {
        return false;
      }

      if (maxPrepTimeMinutes != null) {
        final prepTime = item.recipe.prepTimeMinutes;
        if (prepTime == null || prepTime > maxPrepTimeMinutes!) return false;
      }

      return true;
    }).toList();
  }

  RecipeState copyWith({
    List<RecipeWithDetails>? recipes,
    bool? isLoading,
    String? errorMessage,
    String? searchQuery,
    bool? favoritesOnly,
    String? tagFilterId,
    bool clearTagFilter = false,
    int? maxPrepTimeMinutes,
    bool clearMaxPrepTime = false,
  }) {
    return RecipeState(
      recipes: recipes ?? this.recipes,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      favoritesOnly: favoritesOnly ?? this.favoritesOnly,
      tagFilterId: clearTagFilter ? null : (tagFilterId ?? this.tagFilterId),
      maxPrepTimeMinutes:
          clearMaxPrepTime ? null : (maxPrepTimeMinutes ?? this.maxPrepTimeMinutes),
    );
  }
}
