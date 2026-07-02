import '../models/recipe_version.dart';

/// UI-facing state for one recipe's version history.
class RecipeVersionState {
  final List<RecipeVersion> versions;
  final bool isLoading;
  final String? errorMessage;

  const RecipeVersionState({
    this.versions = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  RecipeVersionState copyWith({
    List<RecipeVersion>? versions,
    bool? isLoading,
    String? errorMessage,
  }) {
    return RecipeVersionState(
      versions: versions ?? this.versions,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}
