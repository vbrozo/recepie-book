import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'recipe_notifier.dart';
import 'recipe_repository_provider.dart';
import 'recipe_state.dart';

/// UI entry point: `ref.watch(recipeListProvider)` for state,
/// `ref.read(recipeListProvider.notifier)` for actions.
final recipeListProvider =
    StateNotifierProvider<RecipeNotifier, RecipeState>((ref) {
  final repository = ref.watch(recipeRepositoryProvider);
  return RecipeNotifier(repository)..loadRecipes();
});
