import '../models/recipe_with_details.dart';

/// UI-facing state for the recipe list/search screen.
class RecipeState {
  final List<RecipeWithDetails> recipes;
  final bool isLoading;
  final String? errorMessage;
  final String searchQuery;

  const RecipeState({
    this.recipes = const [],
    this.isLoading = false,
    this.errorMessage,
    this.searchQuery = '',
  });

  bool get isSearching => searchQuery.isNotEmpty;

  RecipeState copyWith({
    List<RecipeWithDetails>? recipes,
    bool? isLoading,
    String? errorMessage,
    String? searchQuery,
  }) {
    return RecipeState(
      recipes: recipes ?? this.recipes,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}
