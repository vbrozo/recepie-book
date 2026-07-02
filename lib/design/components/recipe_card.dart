import 'package:flutter/material.dart';

import '../../models/recipe_with_details.dart';
import '../../widgets/recipe_image_thumbnail.dart';
import '../app_colors.dart';
import '../app_typography.dart';

enum RecipeCardVariant { large, grid }

/// Image + name + meta (time, category, favorite heart).
/// [RecipeCardVariant.large] is the 198×148 "Nedavno dodano" card,
/// [RecipeCardVariant.grid] is the ~180×118 2-column Lista recepata card.
class RecipeCard extends StatelessWidget {
  const RecipeCard({
    super.key,
    required this.item,
    required this.onTap,
    this.onFavoriteToggle,
    this.variant = RecipeCardVariant.grid,
    this.width,
  });

  final RecipeWithDetails item;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteToggle;
  final RecipeCardVariant variant;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final recipe = item.recipe;
    final imageHeight = variant == RecipeCardVariant.large ? 148.0 : 118.0;
    final cardWidth = width ?? (variant == RecipeCardVariant.large ? 198.0 : null);

    String? coverPath;
    for (final image in item.images) {
      if (image.isPrimary) {
        coverPath = image.filePath;
        break;
      }
    }
    coverPath ??= item.images.isNotEmpty ? item.images.first.filePath : null;

    final card = GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: coverPath != null
                    ? RecipeImageThumbnail(
                        relativePath: coverPath,
                        width: cardWidth ?? double.infinity,
                        height: imageHeight,
                        radius: 20,
                      )
                    : Container(
                        width: cardWidth ?? double.infinity,
                        height: imageHeight,
                        decoration: BoxDecoration(
                          color: AppColors.oliveSoft,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.restaurant_menu, color: AppColors.olive),
                      ),
              ),
              if (recipe.isFavorite)
                const Positioned(
                  top: 8,
                  right: 8,
                  child: _FavoriteBadge(),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            recipe.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.serif(fontSize: variant == RecipeCardVariant.large ? 18 : 16),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.access_time, size: 14, color: AppColors.muted),
              const SizedBox(width: 4),
              Text(
                recipe.prepTimeMinutes != null ? '${recipe.prepTimeMinutes} min' : '—',
                style: AppTypography.sans(fontSize: 12, color: AppColors.muted),
              ),
              if (onFavoriteToggle != null) ...[
                const Spacer(),
                GestureDetector(
                  onTap: onFavoriteToggle,
                  child: Icon(
                    recipe.isFavorite ? Icons.favorite : Icons.favorite_border,
                    size: 16,
                    color: recipe.isFavorite ? AppColors.orange : AppColors.faint,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );

    return cardWidth != null ? SizedBox(width: cardWidth, child: card) : card;
  }
}

class _FavoriteBadge extends StatelessWidget {
  const _FavoriteBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: const Icon(Icons.favorite, size: 16, color: AppColors.orange),
    );
  }
}
