import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'recipe_version_notifier.dart';
import 'recipe_version_repository_provider.dart';
import 'recipe_version_state.dart';

/// UI entry point, scoped per recipe: `ref.watch(recipeVersionsProvider(id))`
/// for state, `ref.read(recipeVersionsProvider(id).notifier)` for actions.
final recipeVersionsProvider =
    StateNotifierProvider.family<RecipeVersionNotifier, RecipeVersionState, String>(
  (ref, recipeId) {
    final repository = ref.watch(recipeVersionRepositoryProvider);
    return RecipeVersionNotifier(repository, recipeId)..loadVersions();
  },
);
