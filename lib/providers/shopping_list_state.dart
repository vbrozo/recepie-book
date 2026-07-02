import '../models/shopping_list_item.dart';

const _uncategorized = 'Bez kategorije';

/// UI-facing state for the shopping list screen.
class ShoppingListState {
  final List<ShoppingListItem> items;
  final bool isLoading;
  final String? errorMessage;

  const ShoppingListState({
    this.items = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  bool get hasCompleted => items.any((item) => item.isChecked);

  /// Items grouped by [ShoppingListItem.category] (falling back to
  /// [_uncategorized]), each group sorted with unchecked items first.
  Map<String, List<ShoppingListItem>> get groupedByCategory {
    final groups = <String, List<ShoppingListItem>>{};
    for (final item in items) {
      final key = (item.category == null || item.category!.trim().isEmpty)
          ? _uncategorized
          : item.category!.trim();
      groups.putIfAbsent(key, () => []).add(item);
    }

    for (final group in groups.values) {
      group.sort((a, b) {
        if (a.isChecked != b.isChecked) return a.isChecked ? 1 : -1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    }

    return groups;
  }

  ShoppingListState copyWith({
    List<ShoppingListItem>? items,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ShoppingListState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}
