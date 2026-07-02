import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/image_storage_provider.dart';

/// Resolves a `recipe_images.file_path` (relative, as stored in the DB) to
/// an absolute file and renders it. Falls back to a placeholder icon while
/// resolving or if the file is missing.
class RecipeImageThumbnail extends ConsumerWidget {
  const RecipeImageThumbnail({
    super.key,
    required this.relativePath,
    this.size = 80,
  });

  final String relativePath;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageStorage = ref.watch(imageStorageServiceProvider);

    return FutureBuilder<String>(
      future: imageStorage.absolutePath(relativePath),
      builder: (context, snapshot) {
        final path = snapshot.data;
        if (path == null) {
          return _placeholder();
        }

        final file = File(path);
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            file,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _placeholder(),
          ),
        );
      },
    );
  }

  Widget _placeholder() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.image_outlined),
    );
  }
}
