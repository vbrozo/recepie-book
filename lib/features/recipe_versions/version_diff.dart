import '../../models/ingredient.dart';
import '../../models/recipe_snapshot.dart';
import '../../models/recipe_version.dart';

class VersionDiff {
  const VersionDiff({this.added = const [], this.removed = const [], this.changed = const []});

  final List<String> added;
  final List<String> removed;

  /// Same ingredient (by name) present in both versions, but with a
  /// different quantity and/or unit — e.g. `"Sol: 1 žličica → 2 žličice"`.
  /// This is the case a plain added/removed-by-name diff misses entirely,
  /// which is most of what people actually change between recipe edits
  /// ("više soli, manje brašna").
  final List<String> changed;
}

/// Ingredient diff between [previous] (chronologically before, or null for
/// the very first version) and [current]. Purely a UI-layer read of two
/// already-fetched snapshots — no repository/schema involvement.
VersionDiff computeVersionDiff(RecipeVersion? previous, RecipeVersion current) {
  if (previous == null) return const VersionDiff();

  final previousByName = <String, Ingredient>{
    for (final ingredient in RecipeSnapshot.fromVersion(previous).ingredients)
      ingredient.name.trim().toLowerCase(): ingredient,
  };
  final currentByName = <String, Ingredient>{
    for (final ingredient in RecipeSnapshot.fromVersion(current).ingredients)
      ingredient.name.trim().toLowerCase(): ingredient,
  };

  final added = <String>[];
  final changed = <String>[];
  for (final entry in currentByName.entries) {
    final previousIngredient = previousByName[entry.key];
    if (previousIngredient == null) {
      added.add(entry.value.name);
    } else if (previousIngredient.quantity != entry.value.quantity || previousIngredient.unit != entry.value.unit) {
      changed.add(
        '${entry.value.name}: ${_formatAmount(previousIngredient)} → ${_formatAmount(entry.value)}',
      );
    }
  }

  final removed = [
    for (final entry in previousByName.entries)
      if (!currentByName.containsKey(entry.key)) entry.value.name,
  ];

  return VersionDiff(added: added, removed: removed, changed: changed);
}

String _formatAmount(Ingredient ingredient) {
  final parts = [
    if (ingredient.quantity != null) _trimTrailingZero(ingredient.quantity!),
    if (ingredient.unit != null && ingredient.unit!.trim().isNotEmpty) ingredient.unit!.trim(),
  ];
  return parts.isEmpty ? '—' : parts.join(' ');
}

String _trimTrailingZero(double value) {
  return value == value.roundToDouble() ? value.toInt().toString() : value.toString();
}
