import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';
import '../../../design/app_typography.dart';
import '../../../models/recipe_with_details.dart';
import '../../../widgets/recipe_image_thumbnail.dart';

/// 62×62 thumbnail, name, meta, trailing filled heart — used in Home's
/// "Omiljeni" list.
class CompactRecipeRow extends StatelessWidget {
  const CompactRecipeRow({super.key, required this.item, required this.onTap});

  final RecipeWithDetails item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final recipe = item.recipe;
    String? coverPath;
    for (final image in item.images) {
      if (image.isPrimary) {
        coverPath = image.filePath;
        break;
      }
    }
    coverPath ??= item.images.isNotEmpty ? item.images.first.filePath : null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            coverPath != null
                ? RecipeImageThumbnail(relativePath: coverPath, size: 62, radius: 14)
                : Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(color: context.colors.oliveSoft, borderRadius: BorderRadius.circular(14)),
                    child: Icon(Icons.restaurant_menu, color: context.colors.olive, size: 20),
                  ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(recipe.title, style: context.typography.serif(fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 13, color: context.colors.muted),
                      const SizedBox(width: 4),
                      Text(
                        recipe.prepTimeMinutes != null ? '${recipe.prepTimeMinutes} min' : '—',
                        style: context.typography.sans(fontSize: 12, color: context.colors.muted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.favorite, color: context.colors.orange, size: 20),
          ],
        ),
      ),
    );
  }
}
