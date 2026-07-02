import 'package:flutter_test/flutter_test.dart';

import 'package:recepie_book/models/ingredient.dart';
import 'package:recepie_book/repositories/shopping_list_repository.dart';

import 'test_database.dart';

final _fixedTimestamp = DateTime(2026, 1, 1);

Ingredient _ingredient({required String name, double? quantity, String? unit}) {
  return Ingredient(
    id: 'ignored',
    recipeId: 'r1',
    name: name,
    quantity: quantity,
    unit: unit,
    createdAt: _fixedTimestamp,
    updatedAt: _fixedTimestamp,
  );
}

void main() {
  late ShoppingListRepository repository;

  setUpAll(initTestDatabaseFactory);

  setUp(() {
    repository = ShoppingListRepository(databaseHelper: newTestDatabaseHelper());
  });

  test('addItem creates a new row when nothing matches', () async {
    await repository.addItem(name: 'Jaja', quantity: 6, unit: 'kom');

    final items = await repository.getAllItems();
    expect(items, hasLength(1));
    expect(items.single.name, 'Jaja');
    expect(items.single.quantity, 6);
  });

  test('addItem merges quantity into an existing unchecked item with the same name and unit', () async {
    await repository.addItem(name: 'Brašno', quantity: 200, unit: 'g');
    await repository.addItem(name: 'brašno', quantity: 300, unit: 'g'); // case-insensitive match

    final items = await repository.getAllItems();
    expect(items, hasLength(1));
    expect(items.single.quantity, 500);
  });

  test('does not merge items with different units', () async {
    await repository.addItem(name: 'Mlijeko', quantity: 1, unit: 'l');
    await repository.addItem(name: 'Mlijeko', quantity: 200, unit: 'ml');

    final items = await repository.getAllItems();
    expect(items, hasLength(2));
  });

  test('does not merge into an already-checked item', () async {
    await repository.addItem(name: 'Šećer', quantity: 100, unit: 'g');
    final firstId = (await repository.getAllItems()).single.id;
    await repository.toggleChecked(firstId);

    await repository.addItem(name: 'Šećer', quantity: 50, unit: 'g');

    final items = await repository.getAllItems();
    expect(items, hasLength(2));
    final checked = items.firstWhere((i) => i.id == firstId);
    final unchecked = items.firstWhere((i) => i.id != firstId);
    expect(checked.quantity, 100);
    expect(unchecked.quantity, 50);
    expect(unchecked.isChecked, isFalse);
  });

  test('addIngredientsFromRecipe merges duplicates across ingredients and calls', () async {
    await repository.addIngredientsFromRecipe(
      recipeId: 'r1',
      ingredients: [
        _ingredient(name: 'Sol', quantity: 1, unit: 'žličica'),
        _ingredient(name: 'Sol', quantity: 1, unit: 'žličica'),
      ],
    );
    await repository.addIngredientsFromRecipe(
      recipeId: 'r2',
      ingredients: [_ingredient(name: 'Sol', quantity: 1, unit: 'žličica')],
    );

    final items = await repository.getAllItems();
    expect(items, hasLength(1));
    expect(items.single.quantity, 3);
  });

  test('toggleChecked flips is_checked back and forth', () async {
    await repository.addItem(name: 'Kruh');
    final id = (await repository.getAllItems()).single.id;

    await repository.toggleChecked(id);
    expect((await repository.getAllItems()).single.isChecked, isTrue);

    await repository.toggleChecked(id);
    expect((await repository.getAllItems()).single.isChecked, isFalse);
  });

  test('deleteItem removes a single row', () async {
    await repository.addItem(name: 'Kruh');
    await repository.addItem(name: 'Maslac');
    final idToDelete = (await repository.getAllItems()).first.id;

    await repository.deleteItem(idToDelete);

    final items = await repository.getAllItems();
    expect(items, hasLength(1));
    expect(items.any((i) => i.id == idToDelete), isFalse);
  });

  test('clearCompleted removes only checked items', () async {
    await repository.addItem(name: 'Kruh');
    await repository.addItem(name: 'Maslac');
    final items = await repository.getAllItems();
    await repository.toggleChecked(items.first.id);

    await repository.clearCompleted();

    final remaining = await repository.getAllItems();
    expect(remaining, hasLength(1));
    expect(remaining.single.isChecked, isFalse);
  });
}
