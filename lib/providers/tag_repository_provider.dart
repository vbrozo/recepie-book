import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/tag_repository.dart';

final tagRepositoryProvider = Provider<TagRepository>((ref) {
  return TagRepository();
});
