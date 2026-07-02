import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../models/ingredient.dart';
import '../../models/recipe.dart';
import '../../models/recipe_image.dart';
import '../../models/recipe_step.dart';
import '../../models/shopping_list_item.dart';
import '../../repositories/recipe_repository.dart';
import '../../repositories/shopping_list_repository.dart';
import '../../repositories/tag_repository.dart';
import '../storage/image_storage_service.dart';

const _uuid = Uuid();

/// Number of recipes and standalone shopping-list items an import added —
/// shown to the user after a successful import.
class BackupImportResult {
  const BackupImportResult({required this.recipeCount, required this.shoppingItemCount});

  final int recipeCount;
  final int shoppingItemCount;
}

/// Thrown for anything about the selected file that keeps it from being
/// read as a Kuharica backup — shown to the user as-is (Croatian, no stack
/// trace), so messages here should stay short and non-technical.
class BackupFormatException implements Exception {
  const BackupFormatException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Export/import of the whole recipe collection (recipes, their ingredients/
/// steps/tags/images, and the shopping list) as a single `.zip` file, so a
/// user can move their data between installs or recover it after data loss
/// — the only "backup" this offline-first, no-account app can offer.
///
/// Recipe *versions* are deliberately left out: they're a bounded, disposable
/// edit history (see [RecipeVersionRepository]), not primary content, and
/// including every version's full snapshot would bloat the archive for
/// little benefit.
///
/// Import always creates brand-new rows (fresh UUIDs for everything except
/// tags, which are merged by name via [TagRepository.getOrCreateTag]) rather
/// than overwriting anything already in the database — the same "never
/// silently overwrite" rule the app already applies to recipe edits.
class BackupService {
  BackupService({
    RecipeRepository? recipeRepository,
    TagRepository? tagRepository,
    ShoppingListRepository? shoppingListRepository,
    ImageStorageService? imageStorageService,
  })  : _recipeRepository = recipeRepository ?? RecipeRepository(),
        _tagRepository = tagRepository ?? TagRepository(),
        _shoppingListRepository = shoppingListRepository ?? ShoppingListRepository(),
        _imageStorageService = imageStorageService ?? ImageStorageService();

  final RecipeRepository _recipeRepository;
  final TagRepository _tagRepository;
  final ShoppingListRepository _shoppingListRepository;
  final ImageStorageService _imageStorageService;

  static const _formatVersion = 1;
  static const _dataEntryName = 'data.json';
  static const _imagesDirName = 'images';

  /// Builds the full export archive in memory and returns its raw zip
  /// bytes — the caller decides how to hand them to the user (browser
  /// download on web, a save-file dialog on native).
  Future<Uint8List> exportToZipBytes() async {
    final recipes = await _recipeRepository.getAllRecipes();
    final shoppingItems = await _shoppingListRepository.getAllItems();

    final archive = Archive();
    final recipesJson = <Map<String, dynamic>>[];

    for (final item in recipes) {
      final imagesJson = <Map<String, dynamic>>[];
      for (final image in item.images) {
        final bytes = await _imageStorageService.readImageBytes(image.filePath);
        final zipFileName = '${image.id}${_extensionFor(image.filePath)}';
        archive.addFile(ArchiveFile('$_imagesDirName/$zipFileName', bytes.length, bytes));
        imagesJson.add({
          'zipFileName': zipFileName,
          'isPrimary': image.isPrimary,
          'sortOrder': image.sortOrder,
        });
      }

      recipesJson.add({
        'recipe': item.recipe.toJson(),
        'ingredients': item.ingredients.map((i) => i.toJson()).toList(),
        'steps': item.steps.map((s) => s.toJson()).toList(),
        'tagNames': item.tags.map((t) => t.name).toList(),
        'images': imagesJson,
      });
    }

    final data = {
      'formatVersion': _formatVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'recipes': recipesJson,
      'shoppingListItems': shoppingItems.map((i) => i.toJson()).toList(),
    };

    final dataBytes = utf8.encode(json.encode(data));
    archive.addFile(ArchiveFile(_dataEntryName, dataBytes.length, dataBytes));

    final zipBytes = ZipEncoder().encode(archive);
    return Uint8List.fromList(zipBytes);
  }

  /// Parses [zipBytes] as a Kuharica backup and inserts everything it
  /// contains as new rows. Throws [BackupFormatException] for anything that
  /// doesn't look like a backup this version of the app can read; a single
  /// recipe missing one of its images doesn't abort the whole import (that
  /// image is just skipped), since a partially-restored recipe is more
  /// useful than none at all.
  Future<BackupImportResult> importFromZipBytes(Uint8List zipBytes) async {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(zipBytes);
    } catch (_) {
      throw const BackupFormatException('Datoteka nije valjan Kuharica backup (nije ZIP).');
    }

    final dataFile = archive.findFile(_dataEntryName);
    if (dataFile == null) {
      throw const BackupFormatException('Datoteka nije valjan Kuharica backup (nedostaje data.json).');
    }

    final Map<String, dynamic> data;
    try {
      data = json.decode(utf8.decode(dataFile.content)) as Map<String, dynamic>;
    } catch (_) {
      throw const BackupFormatException('Datoteka nije valjan Kuharica backup (data.json nije čitljiv).');
    }

    final formatVersion = data['formatVersion'] as int?;
    if (formatVersion != _formatVersion) {
      throw BackupFormatException('Nepodržana verzija backupa ($formatVersion) — ažuriraj aplikaciju.');
    }

    var importedRecipes = 0;
    for (final rawRecipe in (data['recipes'] as List? ?? const []).cast<Map<String, dynamic>>()) {
      await _importRecipe(rawRecipe, archive);
      importedRecipes++;
    }

    var importedShoppingItems = 0;
    for (final rawItem in (data['shoppingListItems'] as List? ?? const []).cast<Map<String, dynamic>>()) {
      final item = ShoppingListItem.fromJson(rawItem);
      await _shoppingListRepository.addItem(
        name: item.name,
        quantity: item.quantity,
        unit: item.unit,
        category: item.category,
      );
      importedShoppingItems++;
    }

    return BackupImportResult(recipeCount: importedRecipes, shoppingItemCount: importedShoppingItems);
  }

  Future<void> _importRecipe(Map<String, dynamic> rawRecipe, Archive archive) async {
    final now = DateTime.now();
    final newRecipeId = _uuid.v4();

    final originalRecipe = Recipe.fromJson(rawRecipe['recipe'] as Map<String, dynamic>);
    final recipe = originalRecipe.copyWith(
      id: newRecipeId,
      createdAt: now,
      updatedAt: now,
    );

    final ingredients = (rawRecipe['ingredients'] as List? ?? const [])
        .cast<Map<String, dynamic>>()
        .map((m) => Ingredient.fromJson(m).copyWith(
              id: _uuid.v4(),
              recipeId: newRecipeId,
              createdAt: now,
              updatedAt: now,
            ))
        .toList();

    final steps = (rawRecipe['steps'] as List? ?? const [])
        .cast<Map<String, dynamic>>()
        .map((m) => RecipeStep.fromJson(m).copyWith(
              id: _uuid.v4(),
              recipeId: newRecipeId,
              createdAt: now,
              updatedAt: now,
            ))
        .toList();

    final tagIds = <String>[];
    for (final name in (rawRecipe['tagNames'] as List? ?? const []).cast<String>()) {
      final tag = await _tagRepository.getOrCreateTag(name);
      tagIds.add(tag.id);
    }

    final images = <RecipeImage>[];
    for (final rawImage in (rawRecipe['images'] as List? ?? const []).cast<Map<String, dynamic>>()) {
      final zipFileName = rawImage['zipFileName'] as String;
      final archiveFile = archive.findFile('$_imagesDirName/$zipFileName');
      if (archiveFile == null) continue; // Missing image — skip it, keep the rest of the recipe.

      final imageId = _uuid.v4();
      final relativePath = await _imageStorageService.saveImageBytes(
        recipeId: newRecipeId,
        imageId: imageId,
        bytes: archiveFile.content,
        originalFileName: zipFileName,
      );
      images.add(RecipeImage(
        id: imageId,
        recipeId: newRecipeId,
        filePath: relativePath,
        isPrimary: rawImage['isPrimary'] as bool? ?? false,
        sortOrder: rawImage['sortOrder'] as int? ?? 0,
        createdAt: now,
        updatedAt: now,
      ));
    }

    await _recipeRepository.createRecipe(
      recipe: recipe,
      ingredients: ingredients,
      steps: steps,
      images: images,
      tagIds: tagIds,
    );
  }

  /// Mirrors [ImageStorageService]'s mime-type guessing, but in reverse —
  /// picks a file extension for the zip entry from a stored `file_path`,
  /// which is either a native relative path (already has an extension) or
  /// a web `data:<mime>;base64,...` URL (extension has to be derived from
  /// the mime type instead).
  String _extensionFor(String filePath) {
    if (!filePath.startsWith('data:')) {
      return p.extension(filePath);
    }
    final mimeType = filePath.substring(5, filePath.indexOf(';'));
    switch (mimeType) {
      case 'image/png':
        return '.png';
      case 'image/webp':
        return '.webp';
      case 'image/gif':
        return '.gif';
      default:
        return '.jpg';
    }
  }
}
