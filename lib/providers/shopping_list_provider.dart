import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'shopping_list_notifier.dart';
import 'shopping_list_repository_provider.dart';
import 'shopping_list_state.dart';

/// UI entry point: `ref.watch(shoppingListProvider)` for state,
/// `ref.read(shoppingListProvider.notifier)` for actions.
final shoppingListProvider =
    StateNotifierProvider<ShoppingListNotifier, ShoppingListState>((ref) {
  final repository = ref.watch(shoppingListRepositoryProvider);
  return ShoppingListNotifier(repository)..loadItems();
});
