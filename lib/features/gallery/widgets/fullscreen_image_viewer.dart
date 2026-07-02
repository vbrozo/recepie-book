import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/image_storage_provider.dart';

/// Standard fullscreen gallery/lightbox: swipe between photos, pinch to
/// zoom, close button.
class FullscreenImageViewer extends ConsumerStatefulWidget {
  const FullscreenImageViewer({super.key, required this.relativePaths, required this.initialIndex});

  final List<String> relativePaths;
  final int initialIndex;

  @override
  ConsumerState<FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends ConsumerState<FullscreenImageViewer> {
  late final PageController _controller = PageController(initialPage: widget.initialIndex);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imageStorage = ref.watch(imageStorageServiceProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.relativePaths.length,
            itemBuilder: (context, index) {
              return FutureBuilder<ImageProvider>(
                future: imageStorage.resolveProvider(widget.relativePaths[index]),
                builder: (context, snapshot) {
                  final provider = snapshot.data;
                  if (provider == null) return const SizedBox.shrink();
                  return InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: Center(child: Image(image: provider)),
                  );
                },
              );
            },
          ),
          Positioned(
            top: 12,
            right: 12,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
