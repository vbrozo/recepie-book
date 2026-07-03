import 'package:flutter_test/flutter_test.dart';

import 'package:recepie_book/features/recipe_versions/version_diff.dart';
import 'package:recepie_book/models/ingredient.dart';
import 'package:recepie_book/models/recipe.dart';
import 'package:recepie_book/models/recipe_snapshot.dart';
import 'package:recepie_book/models/recipe_version.dart';

final _ts = DateTime(2026, 1, 1);

Ingredient _ingredient(String name, {double? quantity, String? unit}) {
  return Ingredient(id: name, recipeId: 'r1', name: name, quantity: quantity, unit: unit, createdAt: _ts, updatedAt: _ts);
}

RecipeVersion _version(int versionNumber, List<Ingredient> ingredients) {
  return RecipeVersion(
    id: 'v$versionNumber',
    recipeId: 'r1',
    versionNumber: versionNumber,
    snapshotJson: RecipeSnapshot.encode(
      recipe: Recipe(id: 'r1', title: 'Recept', createdAt: _ts, updatedAt: _ts),
      ingredients: ingredients,
      steps: const [],
      tags: const [],
    ),
    createdAt: _ts,
  );
}

void main() {
  test('the very first version has no diff at all', () {
    final diff = computeVersionDiff(null, _version(1, [_ingredient('Brašno', quantity: 200, unit: 'g')]));
    expect(diff.added, isEmpty);
    expect(diff.removed, isEmpty);
    expect(diff.changed, isEmpty);
  });

  test('detects ingredients added and removed by name', () {
    final previous = _version(1, [_ingredient('Brašno', quantity: 200, unit: 'g')]);
    final current = _version(2, [_ingredient('Šećer', quantity: 100, unit: 'g')]);

    final diff = computeVersionDiff(previous, current);
    expect(diff.added, ['Šećer']);
    expect(diff.removed, ['Brašno']);
    expect(diff.changed, isEmpty);
  });

  test('detects a quantity change on an ingredient present in both versions', () {
    final previous = _version(1, [_ingredient('Sol', quantity: 1, unit: 'žličica')]);
    final current = _version(2, [_ingredient('Sol', quantity: 2, unit: 'žličica')]);

    final diff = computeVersionDiff(previous, current);
    expect(diff.added, isEmpty);
    expect(diff.removed, isEmpty);
    expect(diff.changed, ['Sol: 1 žličica → 2 žličica']);
  });

  test('detects a unit change even when the quantity number stays the same', () {
    final previous = _version(1, [_ingredient('Mlijeko', quantity: 1, unit: 'l')]);
    final current = _version(2, [_ingredient('Mlijeko', quantity: 1, unit: 'dl')]);

    final diff = computeVersionDiff(previous, current);
    expect(diff.changed, ['Mlijeko: 1 l → 1 dl']);
  });

  test('an unchanged ingredient produces no chips at all', () {
    final previous = _version(1, [_ingredient('Brašno', quantity: 200, unit: 'g')]);
    final current = _version(2, [_ingredient('Brašno', quantity: 200, unit: 'g')]);

    final diff = computeVersionDiff(previous, current);
    expect(diff.added, isEmpty);
    expect(diff.removed, isEmpty);
    expect(diff.changed, isEmpty);
  });

  test('name matching ignores case and surrounding whitespace', () {
    final previous = _version(1, [_ingredient(' Brašno ', quantity: 200, unit: 'g')]);
    final current = _version(2, [_ingredient('brašno', quantity: 300, unit: 'g')]);

    final diff = computeVersionDiff(previous, current);
    expect(diff.added, isEmpty);
    expect(diff.removed, isEmpty);
    expect(diff.changed, hasLength(1));
  });
}
