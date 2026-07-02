import 'dart:io';

import 'package:flutter/material.dart';

import '../../../widgets/recipe_image_thumbnail.dart';
import 'image_form_item.dart';

class ImageFormThumbnail extends StatelessWidget {
  const ImageFormThumbnail({
    super.key,
    required this.item,
    required this.isCover,
    required this.onSetCover,
    required this.onRemove,
  });

  final ImageFormItem item;
  final bool isCover;
  final VoidCallback onSetCover;
  final VoidCallback onRemove;

  static const double _size = 88;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: onSetCover,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isCover ? Theme.of(context).colorScheme.primary : Colors.transparent,
                width: 3,
              ),
            ),
            child: item.existingRelativePath != null
                ? RecipeImageThumbnail(relativePath: item.existingRelativePath!, size: _size)
                : ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(item.pickedFile!.path),
                      width: _size,
                      height: _size,
                      fit: BoxFit.cover,
                    ),
                  ),
          ),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: IconButton(
            icon: const Icon(Icons.cancel, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: onRemove,
          ),
        ),
        if (isCover)
          Positioned(
            bottom: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'naslovna',
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ),
      ],
    );
  }
}
