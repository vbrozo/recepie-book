import 'package:flutter_test/flutter_test.dart';

import 'package:recepie_book/models/ingredient.dart';
import 'package:recepie_book/models/recipe.dart';
import 'package:recepie_book/models/recipe_with_details.dart';
import 'package:recepie_book/repositories/recipe_version_repository.dart';

import 'test_database.dart';

final _fixedTimestamp = DateTime(2026, 1, 1);

RecipeWithDetails _recipeWithDetails(String id, {String title = 'Recept', List<Ingredient> ingredients = const []}) {
  return RecipeWithDetails(
    recipe: Recipe(id: id, title: title, createdAt: _fixedTimestamp, updatedAt: _fixedTimestamp),
    ingredients: ingredients,
  );
}

void main() {
  late RecipeVersionRepository repository;

  setUpAll(initTestDatabaseFactory);

  setUp(() {
    repository = RecipeVersionRepository(databaseHelper: newTestDatabaseHelper());
  });

  test('assigns incrementing version numbers per recipe', () async {
    final v1 = await repository.createVersion(recipe: _recipeWithDetails('r1', title: 'v1'));
    final v2 = await repository.createVersion(recipe: _recipeWithDetails('r1', title: 'v2'));

    expect(v1!.versionNumber, 1);
    expect(v2!.versionNumber, 2);

    final versions = await repository.getVersionsForRecipe('r1');
    expect(versions.map((v) => v.versionNumber), [2, 1]); // newest first
  });

  test('numbers versions independently per recipe', () async {
    await repository.createVersion(recipe: _recipeWithDetails('r1', title: 'v1'));
    await repository.createVersion(recipe: _recipeWithDetails('r1', title: 'v2'));
    final firstOfOther = await repository.createVersion(recipe: _recipeWithDetails('r2'));

    expect(firstOfOther!.versionNumber, 1);
  });

  test('keeps only the most recent maxVersionsPerRecipe rows per recipe', () async {
    const totalSaves = RecipeVersionRepository.maxVersionsPerRecipe + 2; // 12
    for (var i = 1; i <= totalSaves; i++) {
      await repository.createVersion(recipe: _recipeWithDetails('r1', title: 'v$i'));
    }

    final versions = await repository.getVersionsForRecipe('r1');
    expect(versions, hasLength(RecipeVersionRepository.maxVersionsPerRecipe));

    // Version numbers keep incrementing forever — only the oldest rows are
    // dropped, so what's left is the *last* 10: 3..12, newest first.
    expect(
      versions.map((v) => v.versionNumber),
      List<int>.generate(RecipeVersionRepository.maxVersionsPerRecipe, (i) => totalSaves - i),
    );
  });

  test('pruning one recipe does not touch another recipe\'s versions', () async {
    const totalSaves = RecipeVersionRepository.maxVersionsPerRecipe + 3;
    for (var i = 0; i < totalSaves; i++) {
      await repository.createVersion(recipe: _recipeWithDetails('r1', title: 'v$i'));
    }
    await repository.createVersion(recipe: _recipeWithDetails('r2'));

    final r1Versions = await repository.getVersionsForRecipe('r1');
    final r2Versions = await repository.getVersionsForRecipe('r2');

    expect(r1Versions, hasLength(RecipeVersionRepository.maxVersionsPerRecipe));
    expect(r2Versions, hasLength(1));
  });

  group('no-op saves', () {
    test('skips creating a version when content is unchanged and no note is given', () async {
      await repository.createVersion(recipe: _recipeWithDetails('r1', title: 'Isti naziv'));
      final second = await repository.createVersion(recipe: _recipeWithDetails('r1', title: 'Isti naziv'));

      expect(second, isNull);
      expect(await repository.getVersionsForRecipe('r1'), hasLength(1));
    });

    test('still creates a version for unchanged content if a note is given', () async {
      await repository.createVersion(recipe: _recipeWithDetails('r1', title: 'Isti naziv'));
      final second = await repository.createVersion(
        recipe: _recipeWithDetails('r1', title: 'Isti naziv'),
        note: 'Probano, ukusno',
      );

      expect(second, isNotNull);
      expect(second!.versionNumber, 2);
      expect(await repository.getVersionsForRecipe('r1'), hasLength(2));
    });

    test('does not skip when ingredient quantities changed even though names did not', () async {
      final ts = _fixedTimestamp;
      await repository.createVersion(
        recipe: _recipeWithDetails('r1', ingredients: [
          Ingredient(id: 'i1', recipeId: 'r1', name: 'Sol', quantity: 1, unit: 'žličica', createdAt: ts, updatedAt: ts),
        ]),
      );
      final second = await repository.createVersion(
        recipe: _recipeWithDetails('r1', ingredients: [
          Ingredient(id: 'i1', recipeId: 'r1', name: 'Sol', quantity: 2, unit: 'žličica', createdAt: ts, updatedAt: ts),
        ]),
      );

      expect(second, isNotNull);
    });
  });
}
