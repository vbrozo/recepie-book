import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/backup/backup_service.dart';
import 'image_storage_provider.dart';
import 'recipe_repository_provider.dart';
import 'shopping_list_repository_provider.dart';
import 'tag_repository_provider.dart';

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(
    recipeRepository: ref.watch(recipeRepositoryProvider),
    tagRepository: ref.watch(tagRepositoryProvider),
    shoppingListRepository: ref.watch(shoppingListRepositoryProvider),
    imageStorageService: ref.watch(imageStorageServiceProvider),
  );
});
