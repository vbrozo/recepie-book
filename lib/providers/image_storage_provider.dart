import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/storage/image_storage_service.dart';

final imageStorageServiceProvider = Provider<ImageStorageService>((ref) {
  return ImageStorageService();
});
