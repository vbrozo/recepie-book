import 'package:uuid/uuid.dart';

import '../core/database/database_helper.dart';
import '../models/tag.dart';

const _uuid = Uuid();

/// CRUD access to tags. Attaching/detaching a tag to a specific recipe is
/// handled by [RecipeRepository.createRecipe]/`updateRecipe` (which
/// wholesale-replace `recipe_tags` from the `tagIds` list) rather than here.
class TagRepository {
  TagRepository({DatabaseHelper? databaseHelper})
      : _dbHelper = databaseHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _dbHelper;

  Future<List<Tag>> getAllTags() async {
    final db = await _dbHelper.database;
    final maps = await db.query('tags', orderBy: 'name COLLATE NOCASE ASC');
    return maps.map(Tag.fromMap).toList();
  }

  /// Returns the existing tag matching [name] (case-insensitive), or
  /// creates a new one if none exists yet.
  Future<Tag> getOrCreateTag(String name) async {
    final db = await _dbHelper.database;
    final trimmed = name.trim();

    final existing = await db.query(
      'tags',
      where: 'name = ? COLLATE NOCASE',
      whereArgs: [trimmed],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      return Tag.fromMap(existing.first);
    }

    final now = DateTime.now();
    final tag = Tag(id: _uuid.v4(), name: trimmed, createdAt: now, updatedAt: now);
    await db.insert('tags', tag.toMap());
    return tag;
  }

  /// Deletes a tag entirely (removes it from every recipe it was attached
  /// to via the `recipe_tags` foreign key cascade).
  Future<void> deleteTag(String id) async {
    final db = await _dbHelper.database;
    await db.delete('tags', where: 'id = ?', whereArgs: [id]);
  }
}
