import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

/// Copies picked images into the app's documents directory (native
/// platforms) and manages their lifecycle on disk. On web there is no
/// filesystem, so images are instead stored inline as base64 `data:` URLs
/// — the value returned by [saveImage] is still just persisted as-is in
/// `recipe_images.file_path`, no schema change needed, since a `data:`
/// URL is just a longer string in the same TEXT column.
class ImageStorageService {
  static const _imagesDirName = 'recipe_images';

  /// Persists [source] for [recipeId] and returns the value to store in
  /// `recipe_images.file_path`: a relative filesystem path on native
  /// platforms, or a `data:` URL on web.
  Future<String> saveImage({
    required String recipeId,
    required String imageId,
    required XFile source,
  }) async {
    if (kIsWeb) {
      final bytes = await source.readAsBytes();
      final mimeType = source.mimeType ?? _guessMimeType(source.name);
      return 'data:$mimeType;base64,${base64Encode(bytes)}';
    }

    final dir = await _recipeDir(recipeId);
    final fileExtension = extension(source.path);
    final destinationPath = join(dir.path, '$imageId$fileExtension');
    await File(source.path).copy(destinationPath);
    return join(_imagesDirName, recipeId, '$imageId$fileExtension');
  }

  /// Resolves a stored `file_path` value to something an `Image` widget
  /// can render, on any platform.
  Future<ImageProvider> resolveProvider(String relativePath) async {
    if (relativePath.startsWith('data:')) {
      final base64Data = relativePath.substring(relativePath.indexOf(',') + 1);
      return MemoryImage(base64Decode(base64Data));
    }

    final baseDir = await getApplicationDocumentsDirectory();
    return FileImage(File(join(baseDir.path, relativePath)));
  }

  Future<void> deleteImage(String relativePath) async {
    // Web images live inline in the DB row itself (data: URL) — deleting
    // the row is enough, there's no separate file to remove.
    if (kIsWeb || relativePath.startsWith('data:')) return;

    final baseDir = await getApplicationDocumentsDirectory();
    final file = File(join(baseDir.path, relativePath));
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

  String _guessMimeType(String filename) {
    switch (extension(filename).toLowerCase()) {
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      case '.gif':
        return 'image/gif';
      default:
        return 'image/jpeg';
    }
  }
}
