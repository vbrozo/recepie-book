import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

/// Copies picked images into the app's documents directory and manages
/// their lifecycle on disk. The database only stores the *relative* path
/// returned by [saveImage] (see ARCHITECTURE.md §5) — this service is the
/// only place that knows about the app's document root.
class ImageStorageService {
  static const _imagesDirName = 'recipe_images';

  /// Copies [sourcePath] into `<app documents>/recipe_images/<recipeId>/`
  /// and returns the relative path to persist in `recipe_images.file_path`.
  Future<String> saveImage({
    required String recipeId,
    required String imageId,
    required String sourcePath,
  }) async {
    final dir = await _recipeDir(recipeId);
    final fileExtension = extension(sourcePath);
    final destinationPath = join(dir.path, '$imageId$fileExtension');
    await File(sourcePath).copy(destinationPath);
    return join(_imagesDirName, recipeId, '$imageId$fileExtension');
  }

  /// Resolves a relative `file_path` (as stored in the DB) to an absolute
  /// path usable by `File(...)`/`Image.file(...)`.
  Future<String> absolutePath(String relativePath) async {
    final baseDir = await getApplicationDocumentsDirectory();
    return join(baseDir.path, relativePath);
  }

  Future<void> deleteImage(String relativePath) async {
    final path = await absolutePath(relativePath);
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> deleteImages(Iterable<String> relativePaths) async {
    for (final path in relativePaths) {
      await deleteImage(path);
    }
  }

  Future<Directory> _recipeDir(String recipeId) async {
    final baseDir = await getApplicationDocumentsDirectory();
    final dir = Directory(join(baseDir.path, _imagesDirName, recipeId));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }
}
