import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ingredient.dart';
import '../repositories/shopping_list_repository.dart';
import 'shopping_list_state.dart';

class ShoppingListNotifier extends StateNotifier<ShoppingListState> {
  ShoppingListNotifier(this._repository) : super(const ShoppingListState());

  final ShoppingListRepository _repository;

  Future<void> loadItems() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final items = await _repository.getAllItems();
      state = state.copyWith(items: items, isLoading: false);
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
    }
  }

  Future<void> addManualItem({
    required String name,
    double? quantity,
    String? unit,
    String? category,
  }) async {
    try {
      await _repository.addItem(name: name, quantity: quantity, unit: unit, category: category);
      await loadItems();
    } catch (error) {
      state = state.copyWith(errorMessage: error.toString());
    }
  }

  /// Adds every ingredient of a recipe to the list, merging with existing
  /// unchecked items that share the same name and unit.
  Future<void> addIngredientsFromRecipe({
    required String recipeId,
    required List<Ingredient> ingredients,
  }) async {
    try {
      await _repository.addIngredientsFromRecipe(recipeId: recipeId, ingredients: ingredients);
      await loadItems();
    } catch (error) {
      state = state.copyWith(errorMessage: error.toString());
    }
  }

  Future<void> toggleChecked(String id) async {
    final index = state.items.indexWhere((item) => item.id == id);
    if (index == -1) return;

    final previousItems = state.items;
    final target = previousItems[index];
    final optimisticItems = [...previousItems]
      ..[index] = target.copyWith(isChecked: !target.isChecked);
    state = state.copyWith(items: optimisticItems, errorMessage: null);

    try {
      await _repository.toggleChecked(id);
    } catch (error) {
      state = state.copyWith(items: previousItems, errorMessage: error.toString());
    }
  }

  Future<void> deleteItem(String id) async {
    final previousItems = state.items;
    state = state.copyWith(
      items: previousItems.where((item) => item.id != id).toList(),
      errorMessage: null,
    );

    try {
      await _repository.deleteItem(id);
    } catch (error) {
      state = state.copyWith(items: previousItems, errorMessage: error.toString());
    }
  }

  Future<void> clearCompleted() async {
    final previousItems = state.items;
    state = state.copyWith(
      items: previousItems.where((item) => !item.isChecked).toList(),
      errorMessage: null,
    );

    try {
      await _repository.clearCompleted();
    } catch (error) {
      state = state.copyWith(items: previousItems, errorMessage: error.toString());
    }
  }
}
