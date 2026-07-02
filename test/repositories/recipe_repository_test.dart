import 'package:flutter_test/flutter_test.dart';

import 'package:recepie_book/models/ingredient.dart';
import 'package:recepie_book/models/recipe.dart';
import 'package:recepie_book/models/recipe_step.dart';
import 'package:recepie_book/repositories/recipe_repository.dart';
import 'package:recepie_book/repositories/tag_repository.dart';

import 'test_database.dart';

final _fixedTimestamp = DateTime(2026, 1, 1);

Recipe _recipe(String id, {String title = 'Recept'}) {
  return Recipe(id: id, title: title, createdAt: _fixedTimestamp, updatedAt: _fixedTimestamp);
}

Ingredient _ingredient(String id, String recipeId, {required String name, int sortOrder = 0}) {
  return Ingredient(
    id: id,
    recipeId: recipeId,
    name: name,
    sortOrder: sortOrder,
    createdAt: _fixedTimestamp,
    updatedAt: _fixedTimestamp,
  );
}

RecipeStep _step(String id, String recipeId, {required int stepNumber, String instruction = 'Napravi'}) {
  return RecipeStep(
    id: id,
    recipeId: recipeId,
    stepNumber: stepNumber,
    instruction: instruction,
    createdAt: _fixedTimestamp,
    updatedAt: _fixedTimestamp,
  );
}

void main() {
  late RecipeRepository repository;
  late TagRepository tagRepository;

  setUpAll(initTestDatabaseFactory);

  setUp(() {
    final dbHelper = newTestDatabaseHelper();
    repository = RecipeRepository(databaseHelper: dbHelper);
    tagRepository = TagRepository(databaseHelper: dbHelper);
  });

  group('createRecipe / getAllRecipes', () {
    test('persists a recipe with its ingredients, steps and tags in order', () async {
      final tag = await tagRepository.getOrCreateTag('Vegetarijansko');
      await repository.createRecipe(
        recipe: _recipe('r1', title: 'Palačinke'),
        ingredients: [
          _ingredient('i2', 'r1', name: 'Mlijeko', sortOrder: 1),
          _ingredient('i1', 'r1', name: 'Brašno', sortOrder: 0),
        ],
        steps: [
          _step('s2', 'r1', stepNumber: 2, instruction: 'Peci'),
          _step('s1', 'r1', stepNumber: 1, instruction: 'Zamijesi'),
        ],
        tagIds: [tag.id],
      );

      final all = await repository.getAllRecipes();
      expect(all, hasLength(1));
      final item = all.single;
      expect(item.recipe.title, 'Palačinke');
      expect(item.ingredients.map((i) => i.name), ['Brašno', 'Mlijeko']);
      expect(item.steps.map((s) => s.instruction), ['Zamijesi', 'Peci']);
      expect(item.tags.map((t) => t.name), ['Vegetarijansko']);
    });

    test('keeps each recipe scoped to its own children when loading many at once', () async {
      // Regression test for the N+1 fix: getAllRecipes now batch-loads
      // ingredients/steps/tags for every recipe in a handful of queries
      // instead of one round-trip per recipe — this checks the grouping
      // logic doesn't cross-contaminate recipes.
      final tagA = await tagRepository.getOrCreateTag('A');
      final tagB = await tagRepository.getOrCreateTag('B');

      await repository.createRecipe(
        recipe: _recipe('r1', title: 'Recept A'),
        ingredients: [_ingredient('i1', 'r1', name: 'Sastojak A')],
        steps: [_step('s1', 'r1', stepNumber: 1)],
        tagIds: [tagA.id],
      );
      await repository.createRecipe(
        recipe: _recipe('r2', title: 'Recept B'),
        ingredients: [_ingredient('i2', 'r2', name: 'Sastojak B')],
        steps: [_step('s2', 'r2', stepNumber: 1)],
        tagIds: [tagB.id],
      );

      final all = await repository.getAllRecipes();
      expect(all, hasLength(2));

      final recipeA = all.firstWhere((r) => r.recipe.id == 'r1');
      final recipeB = all.firstWhere((r) => r.recipe.id == 'r2');

      expect(recipeA.ingredients.map((i) => i.name), ['Sastojak A']);
      expect(recipeA.tags.map((t) => t.name), ['A']);
      expect(recipeB.ingredients.map((i) => i.name), ['Sastojak B']);
      expect(recipeB.tags.map((t) => t.name), ['B']);
    });

    test('a recipe with no children returns empty lists, not a crash', () async {
      await repository.createRecipe(recipe: _recipe('r1'));
      final all = await repository.getAllRecipes();
      expect(all.single.ingredients, isEmpty);
      expect(all.single.steps, isEmpty);
      expect(all.single.tags, isEmpty);
    });

    test('orders recipes by title, case-insensitively', () async {
      await repository.createRecipe(recipe: _recipe('r1', title: 'čokolada'));
      await repository.createRecipe(recipe: _recipe('r2', title: 'Banana'));
      await repository.createRecipe(recipe: _recipe('r3', title: 'ananas'));

      final all = await repository.getAllRecipes();
      expect(all.map((r) => r.recipe.title), ['ananas', 'Banana', 'čokolada']);
    });
  });

  group('getRecipeById', () {
    test('returns null for an unknown id', () async {
      expect(await repository.getRecipeById('missing'), isNull);
    });

    test('returns the recipe with its children', () async {
      await repository.createRecipe(
        recipe: _recipe('r1', title: 'Juha'),
        ingredients: [_ingredient('i1', 'r1', name: 'Voda')],
      );
      final found = await repository.getRecipeById('r1');
      expect(found, isNotNull);
      expect(found!.recipe.title, 'Juha');
      expect(found.ingredients.single.name, 'Voda');
    });
  });

  group('updateRecipe', () {
    test('wholesale replaces ingredients and tags', () async {
      final tagOld = await tagRepository.getOrCreateTag('Staro');
      final tagNew = await tagRepository.getOrCreateTag('Novo');

      await repository.createRecipe(
        recipe: _recipe('r1', title: 'Recept'),
        ingredients: [_ingredient('i1', 'r1', name: 'Staro')],
        tagIds: [tagOld.id],
      );

      final existing = await repository.getRecipeById('r1');
      await repository.updateRecipe(
        recipe: existing!.recipe.copyWith(title: 'Recept v2'),
        ingredients: [_ingredient('i2', 'r1', name: 'Novo')],
        tagIds: [tagNew.id],
      );

      final updated = await repository.getRecipeById('r1');
      expect(updated!.recipe.title, 'Recept v2');
      expect(updated.ingredients.map((i) => i.name), ['Novo']);
      expect(updated.tags.map((t) => t.name), ['Novo']);
    });

    test('bumps updatedAt on every call, ignoring the value passed in', () async {
      await repository.createRecipe(recipe: _recipe('r1'));
      final before = DateTime.now();
      await Future<void>.delayed(const Duration(milliseconds: 5));

      await repository.updateRecipe(recipe: _recipe('r1', title: 'Preimenovano'));

      final after = (await repository.getRecipeById('r1'))!.recipe.updatedAt;
      expect(after.isAfter(before), isTrue);
    });
  });

  group('deleteRecipe', () {
    test('removes the recipe and cascades its children, returning image paths', () async {
      await repository.createRecipe(
        recipe: _recipe('r1'),
        ingredients: [_ingredient('i1', 'r1', name: 'X')],
      );

      final imagePaths = await repository.deleteRecipe('r1');
      expect(imagePaths, isEmpty);
      expect(await repository.getRecipeById('r1'), isNull);
      expect(await repository.getAllRecipes(), isEmpty);
    });
  });

  group('searchRecipes', () {
    test('matches title, case-insensitively', () async {
      await repository.createRecipe(recipe: _recipe('r1', title: 'Pileća juha'));
      await repository.createRecipe(recipe: _recipe('r2', title: 'Kolač'));

      final results = await repository.searchRecipes('pile');
      expect(results.map((r) => r.recipe.id), ['r1']);
    });

    test('returns no results, not an error, when nothing matches', () async {
      await repository.createRecipe(recipe: _recipe('r1', title: 'Kolač'));
      expect(await repository.searchRecipes('nepostojeće'), isEmpty);
    });
  });

  group('toggleFavorite', () {
    test('flips is_favorite back and forth', () async {
      await repository.createRecipe(recipe: _recipe('r1'));

      await repository.toggleFavorite('r1');
      expect((await repository.getRecipeById('r1'))!.recipe.isFavorite, isTrue);

      await repository.toggleFavorite('r1');
      expect((await repository.getRecipeById('r1'))!.recipe.isFavorite, isFalse);
    });
  });
}
