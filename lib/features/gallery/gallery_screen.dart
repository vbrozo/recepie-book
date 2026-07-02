import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../design/app_colors.dart';
import '../../design/app_typography.dart';
import '../../design/components/empty_state.dart';
import '../../models/recipe_image.dart';
import '../../models/recipe_with_details.dart';
import '../../providers/recipe_list_provider.dart';
import '../../widgets/recipe_image_thumbnail.dart';
import 'widgets/fullscreen_image_viewer.dart';

const _leftHeights = [210.0, 140.0, 175.0];
const _rightHeights = [140.0, 210.0];

/// All photos attached to one recipe, masonry-style. Tap opens a fullscreen
/// swipeable/zoomable viewer.
class GalleryScreen extends ConsumerWidget {
  const GalleryScreen({super.key, required this.recipeId});

  final String recipeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(recipeListProvider);

    RecipeWithDetails? item;
    for (final recipe in state.recipes) {
      if (recipe.recipe.id == recipeId) {
        item = recipe;
        break;
      }
    }

    if (item == null) {
      return Scaffold(backgroundColor: context.colors.background, body: const SizedBox.shrink());
    }

    final images = item.images;
    final left = <int>[];
    final right = <int>[];
    for (var i = 0; i < images.length; i++) {
      (i.isEven ? left : right).add(i);
    }

    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 20, 0),
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
                  Text('Galerija', style: context.typography.sans(fontSize: 17, fontWeight: FontWeight.w700, color: context.colors.ink)),
                  const Spacer(),
                  Text('${images.length} slika', style: context.typography.sans(fontSize: 13, color: context.colors.muted)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 56),
              child: Text(item.recipe.title, style: context.typography.serif(fontSize: 16)),
            ),
            Expanded(
              child: images.isEmpty
                  ? const EmptyState(icon: Icons.photo_library_outlined, message: 'Nema slika za ovaj recept.')
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _MasonryColumn(
                              indices: left,
                              heights: _leftHeights,
                              images: images,
                              onTap: (index) => _openViewer(context, images, index),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _MasonryColumn(
                              indices: right,
                              heights: _rightHeights,
                              images: images,
                              onTap: (index) => _openViewer(context, images, index),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            if (images.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Center(
                  child: Text(
                    'Dodir otvara sliku preko cijelog ekrana',
                    style: context.typography.sans(fontSize: 12, color: context.colors.faint),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _openViewer(BuildContext context, List<RecipeImage> images, int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullscreenImageViewer(
          relativePaths: images.map((image) => image.filePath).toList(),
          initialIndex: index,
        ),
      ),
    );
  }
}

class _MasonryColumn extends StatelessWidget {
  const _MasonryColumn({required this.indices, required this.heights, required this.images, required this.onTap});

  final List<int> indices;
  final List<double> heights;
  final List<RecipeImage> images;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < indices.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () => onTap(indices[i]),
              child: RecipeImageThumbnail(
                relativePath: images[indices[i]].filePath,
                width: double.infinity,
                height: heights[i % heights.length],
                radius: 18,
              ),
            ),
          ),
      ],
    );
  }
}
