import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/tag.dart';
import '../repositories/tag_repository.dart';

/// Holds the full list of tags in the app (used for the tag manager screen,
/// the tag filter and the tag picker in the recipe form).
class TagNotifier extends StateNotifier<List<Tag>> {
  TagNotifier(this._repository) : super(const []);

  final TagRepository _repository;

  Future<void> loadTags() async {
    state = await _repository.getAllTags();
  }

  Future<Tag> getOrCreateTag(String name) async {
    final tag = await _repository.getOrCreateTag(name);
    await loadTags();
    return tag;
  }

  Future<void> deleteTag(String id) async {
    await _repository.deleteTag(id);
    await loadTags();
  }
}
