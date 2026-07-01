import 'dart:convert';

class RecipeVersion {
  final String id;
  final String recipeId;
  final int versionNumber;
  final String snapshotJson;
  final DateTime createdAt;

  const RecipeVersion({
    required this.id,
    required this.recipeId,
    required this.versionNumber,
    required this.snapshotJson,
    required this.createdAt,
  });

  RecipeVersion copyWith({
    String? id,
    String? recipeId,
    int? versionNumber,
    String? snapshotJson,
    DateTime? createdAt,
  }) {
    return RecipeVersion(
      id: id ?? this.id,
      recipeId: recipeId ?? this.recipeId,
      versionNumber: versionNumber ?? this.versionNumber,
      snapshotJson: snapshotJson ?? this.snapshotJson,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory RecipeVersion.fromMap(Map<String, Object?> map) {
    return RecipeVersion(
      id: map['id'] as String,
      recipeId: map['recipe_id'] as String,
      versionNumber: map['version_number'] as int,
      snapshotJson: map['snapshot_json'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'recipe_id': recipeId,
      'version_number': versionNumber,
      'snapshot_json': snapshotJson,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory RecipeVersion.fromJson(Map<String, dynamic> json) {
    return RecipeVersion(
      id: json['id'] as String,
      recipeId: json['recipe_id'] as String,
      versionNumber: json['version_number'] as int,
      snapshotJson: json['snapshot_json'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recipe_id': recipeId,
      'version_number': versionNumber,
      'snapshot_json': snapshotJson,
      'created_at': createdAt.toIso8601String(),
    };
  }

  static RecipeVersion decode(String source) =>
      RecipeVersion.fromJson(json.decode(source) as Map<String, dynamic>);

  String encode() => json.encode(toJson());
}
