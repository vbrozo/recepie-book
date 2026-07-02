import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/tag.dart';
import 'tag_notifier.dart';
import 'tag_repository_provider.dart';

/// UI entry point: `ref.watch(tagListProvider)` for the tag list,
/// `ref.read(tagListProvider.notifier)` for create/delete.
final tagListProvider = StateNotifierProvider<TagNotifier, List<Tag>>((ref) {
  final repository = ref.watch(tagRepositoryProvider);
  return TagNotifier(repository)..loadTags();
});
