import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/recipe_repository.dart';

/// Single shared [RecipeRepository] instance (wraps the [DatabaseHelper]
/// singleton, so this provider is cheap to instantiate).
final recipeRepositoryProvider = Provider<RecipeRepository>((ref) {
  return RecipeRepository();
});
