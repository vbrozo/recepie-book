import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:recepie_book/core/backup/backup_service.dart';
import 'package:recepie_book/core/storage/image_storage_service.dart';
import 'package:recepie_book/models/ingredient.dart';
import 'package:recepie_book/models/recipe.dart';
import 'package:recepie_book/models/recipe_step.dart';
import 'package:recepie_book/repositories/recipe_repository.dart';
import 'package:recepie_book/repositories/shopping_list_repository.dart';
import 'package:recepie_book/repositories/tag_repository.dart';

import '../repositories/test_database.dart';

final _fixedTimestamp = DateTime(2026, 1, 1);

Recipe _recipe(String id, {String title = 'Recept', int? servings, bool isFavorite = false}) {
  return Recipe(
    id: id,
    title: title,
    servings: servings,
    isFavorite: isFavorite,
    createdAt: _fixedTimestamp,
    updatedAt: _fixedTimestamp,
  );
}

Ingredient _ingredient(String id, String recipeId, {required String name, double? quantity, String? unit}) {
  return Ingredient(
    id: id,
    recipeId: recipeId,
    name: name,
    quantity: quantity,
    unit: unit,
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
  late RecipeRepository recipeRepository;
  late TagRepository tagRepository;
  late ShoppingListRepository shoppingListRepository;
  late BackupService backupService;

  setUpAll(initTestDatabaseFactory);

  setUp(() {
    final dbHelper = newTestDatabaseHelper();
    recipeRepository = RecipeRepository(databaseHelper: dbHelper);
    tagRepository = TagRepository(databaseHelper: dbHelper);
    shoppingListRepository = ShoppingListRepository(databaseHelper: dbHelper);
    backupService = BackupService(
      recipeRepository: recipeRepository,
      tagRepository: tagRepository,
      shoppingListRepository: shoppingListRepository,
      // Image bytes go through base64 data: URLs regardless of platform in
      // a plain `dart:io`-less test run (no real filesystem here), which
      // ImageStorageService already does for kIsWeb — fine for round-trip
      // correctness since these tests don't touch real image content.
      imageStorageService: ImageStorageService(),
    );
  });

  test('round-trips an empty collection', () async {
    final bytes = await backupService.exportToZipBytes();
    final result = await backupService.importFromZipBytes(bytes);

    expect(result.recipeCount, 0);
    expect(result.shoppingItemCount, 0);
  });

  test('exports and re-imports a recipe as a new, independent copy', () async {
    final tag = await tagRepository.getOrCreateTag('Vegetarijansko');
    await recipeRepository.createRecipe(
      recipe: _recipe('r1', title: 'Palačinke', servings: 4, isFavorite: true),
      ingredients: [_ingredient('i1', 'r1', name: 'Brašno', quantity: 200, unit: 'g')],
      steps: [_step('s1', 'r1', stepNumber: 1, instruction: 'Zamijesi')],
      tagIds: [tag.id],
    );

    final bytes = await backupService.exportToZipBytes();
    final result = await backupService.importFromZipBytes(bytes);

    expect(result.recipeCount, 1);

    final all = await recipeRepository.getAllRecipes();
    // The import created a brand-new recipe alongside the original —
    // never overwrites/merges into what's already there.
    expect(all, hasLength(2));

    final imported = all.firstWhere((r) => r.recipe.id != 'r1');
    expect(imported.recipe.title, 'Palačinke');
    expect(imported.recipe.servings, 4);
    expect(imported.recipe.isFavorite, isTrue);
    expect(imported.ingredients.single.name, 'Brašno');
    expect(imported.ingredients.single.quantity, 200);
    expect(imported.steps.single.instruction, 'Zamijesi');
    expect(imported.tags.single.name, 'Vegetarijansko');

    // Fresh IDs, not copies of the originals.
    expect(imported.recipe.id, isNot('r1'));
    expect(imported.ingredients.single.id, isNot('i1'));
    expect(imported.steps.single.id, isNot('s1'));
  });

  test('merges tags by name instead of duplicating them on import', () async {
    final tag = await tagRepository.getOrCreateTag('Brzo');
    await recipeRepository.createRecipe(
      recipe: _recipe('r1', title: 'Recept'),
      tagIds: [tag.id],
    );

    final bytes = await backupService.exportToZipBytes();
    await backupService.importFromZipBytes(bytes);

    final allTags = await tagRepository.getAllTags();
    expect(allTags.map((t) => t.name), ['Brzo']); // not ['Brzo', 'Brzo']
  });

  test('imports standalone shopping list items', () async {
    await shoppingListRepository.addItem(name: 'Jaja', quantity: 6, unit: 'kom');

    final bytes = await backupService.exportToZipBytes();
    final result = await backupService.importFromZipBytes(bytes);

    expect(result.shoppingItemCount, 1);
    final items = await shoppingListRepository.getAllItems();
    // Original + re-imported copy merge into one row (addItem merges
    // same name/unit into the existing unchecked item — see
    // ShoppingListRepository), so quantity doubles rather than a second
    // row appearing.
    expect(items, hasLength(1));
    expect(items.single.quantity, 12);
  });

  test('rejects a file that is not a zip', () async {
    final notAZip = Uint8List.fromList('not a zip'.codeUnits);
    expect(
      () => backupService.importFromZipBytes(notAZip),
      throwsA(isA<BackupFormatException>()),
    );
  });

  test('rejects a zip missing data.json', () async {
    final archive = Archive()..addFile(ArchiveFile('other.txt', 3, [1, 2, 3]));
    final zipBytes = Uint8List.fromList(ZipEncoder().encode(archive));

    expect(
      () => backupService.importFromZipBytes(zipBytes),
      throwsA(isA<BackupFormatException>()),
    );
  });

  test('rejects an unsupported format version', () async {
    final archive = Archive();
    final data = utf8.encode(json.encode({'formatVersion': 999, 'recipes': [], 'shoppingListItems': []}));
    archive.addFile(ArchiveFile('data.json', data.length, data));
    final zipBytes = Uint8List.fromList(ZipEncoder().encode(archive));

    expect(
      () => backupService.importFromZipBytes(zipBytes),
      throwsA(isA<BackupFormatException>()),
    );
  });
}
