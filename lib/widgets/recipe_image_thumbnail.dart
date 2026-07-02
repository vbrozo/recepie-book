import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/image_storage_provider.dart';

/// Resolves a `recipe_images.file_path` (relative path on native, `data:`
/// URL on web — see ImageStorageService) to a renderable [ImageProvider].
/// Falls back to a placeholder icon while resolving or if the image is
/// missing/corrupt.
class RecipeImageThumbnail extends ConsumerWidget {
  const RecipeImageThumbnail({
    super.key,
    required this.relativePath,
    this.size = 80,
    double? width,
    double? height,
    this.radius = 8,
    this.placeholderIcon = Icons.image_outlined,
  })  : _width = width,
        _height = height;

  final String relativePath;
  final double size;
  final double? _width;
  final double? _height;
  final double radius;
  final IconData placeholderIcon;

  double get _w => _width ?? size;
  double get _h => _height ?? size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageStorage = ref.watch(imageStorageServiceProvider);

    return FutureBuilder<ImageProvider>(
      future: imageStorage.resolveProvider(relativePath),
      builder: (context, snapshot) {
        final provider = snapshot.data;
        if (provider == null) {
          return _placeholder();
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Image(
            image: provider,
            width: _w,
            height: _h,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _placeholder(),
          ),
        );
      },
    );
  }

  Widget _placeholder() {
    return Container(
      width: _w,
      height: _h,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(placeholderIcon),
    );
  }
}
