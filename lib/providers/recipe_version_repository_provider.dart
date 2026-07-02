import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/recipe_version_repository.dart';

final recipeVersionRepositoryProvider = Provider<RecipeVersionRepository>((ref) {
  return RecipeVersionRepository();
});
