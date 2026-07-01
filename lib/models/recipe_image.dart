import 'dart:convert';

class RecipeImage {
  final String id;
  final String recipeId;
  final String filePath;
  final bool isCover;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RecipeImage({
    required this.id,
    required this.recipeId,
    required this.filePath,
    this.isCover = false,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  RecipeImage copyWith({
    String? id,
    String? recipeId,
    String? filePath,
    bool? isCover,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RecipeImage(
      id: id ?? this.id,
      recipeId: recipeId ?? this.recipeId,
      filePath: filePath ?? this.filePath,
      isCover: isCover ?? this.isCover,
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
      isCover: (map['is_cover'] as int) == 1,
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
      'is_cover': isCover ? 1 : 0,
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
      isCover: json['is_cover'] as bool? ?? false,
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
      'is_cover': isCover,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static RecipeImage decode(String source) =>
      RecipeImage.fromJson(json.decode(source) as Map<String, dynamic>);

  String encode() => json.encode(toJson());
}
