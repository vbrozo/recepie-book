import '../../models/recipe_snapshot.dart';
import '../../models/recipe_version.dart';

class VersionDiff {
  const VersionDiff({this.added = const [], this.removed = const []});

  final List<String> added;
  final List<String> removed;
}

/// Ingredient-name diff between [previous] (chronologically before, or null
/// for the very first version) and [current]. Purely a UI-layer read of two
/// already-fetched snapshots — no repository/schema involvement.
VersionDiff computeVersionDiff(RecipeVersion? previous, RecipeVersion current) {
  if (previous == null) return const VersionDiff();

  final previousNames = RecipeSnapshot.fromVersion(previous).ingredients.map((i) => i.name.trim().toLowerCase()).toSet();
  final currentNames = RecipeSnapshot.fromVersion(current).ingredients.map((i) => i.name.trim().toLowerCase()).toSet();

  return VersionDiff(
    added: currentNames.difference(previousNames).toList(),
    removed: previousNames.difference(currentNames).toList(),
  );
}
