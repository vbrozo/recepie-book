import 'dart:convert';

class RecipeImage {
  final String id;
  final String recipeId;
  final String filePath;
  final bool isPrimary;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RecipeImage({
    required this.id,
    required this.recipeId,
    required this.filePath,
    this.isPrimary = false,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  RecipeImage copyWith({
    String? id,
    String? recipeId,
    String? filePath,
    bool? isPrimary,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RecipeImage(
      id: id ?? this.id,
      recipeId: recipeId ?? this.recipeId,
      filePath: filePath ?? this.filePath,
      isPrimary: isPrimary ?? this.isPrimary,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory RecipeImage.fromMap(Map<String, Object?> map) {
    return RecipeImage(
      id: map['id'] as String,
      recipeId: map['recipe_id'] as String,
      filePath: map['file_path'] as String,
      isPrimary: (map['is_primary'] as int) == 1,
      sortOrder: map['sort_order'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'recipe_id': recipeId,
      'file_path': filePath,
      'is_primary': isPrimary ? 1 : 0,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory RecipeImage.fromJson(Map<String, dynamic> json) {
    return RecipeImage(
      id: json['id'] as String,
      recipeId: json['recipe_id'] as String,
      filePath: json['file_path'] as String,
      isPrimary: json['is_primary'] as bool? ?? false,
      sortOrder: json['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recipe_id': recipeId,
      'file_path': filePath,
      'is_primary': isPrimary,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static RecipeImage decode(String source) =>
      RecipeImage.fromJson(json.decode(source) as Map<String, dynamic>);

  String encode() => json.encode(toJson());
}
