import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/shopping_list_repository.dart';

final shoppingListRepositoryProvider = Provider<ShoppingListRepository>((ref) {
  return ShoppingListRepository();
});
