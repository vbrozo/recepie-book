import 'dart:convert';

class Recipe {
  final String id;
  final String title;
  final String? description;
  final int? servings;
  final int? prepTimeMinutes;
  final int? cookTimeMinutes;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Recipe({
    required this.id,
    required this.title,
    this.description,
    this.servings,
    this.prepTimeMinutes,
    this.cookTimeMinutes,
    this.isFavorite = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Recipe copyWith({
    String? id,
    String? title,
    String? description,
    int? servings,
    int? prepTimeMinutes,
    int? cookTimeMinutes,
    bool? isFavorite,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Recipe(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      servings: servings ?? this.servings,
      prepTimeMinutes: prepTimeMinutes ?? this.prepTimeMinutes,
      cookTimeMinutes: cookTimeMinutes ?? this.cookTimeMinutes,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Recipe.fromMap(Map<String, Object?> map) {
    return Recipe(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      servings: map['servings'] as int?,
      prepTimeMinutes: map['prep_time_minutes'] as int?,
      cookTimeMinutes: map['cook_time_minutes'] as int?,
      isFavorite: (map['is_favorite'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'servings': servings,
      'prep_time_minutes': prepTimeMinutes,
      'cook_time_minutes': cookTimeMinutes,
      'is_favorite': isFavorite ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      servings: json['servings'] as int?,
      prepTimeMinutes: json['prep_time_minutes'] as int?,
      cookTimeMinutes: json['cook_time_minutes'] as int?,
      isFavorite: json['is_favorite'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'servings': servings,
      'prep_time_minutes': prepTimeMinutes,
      'cook_time_minutes': cookTimeMinutes,
      'is_favorite': isFavorite,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static Recipe decode(String source) =>
      Recipe.fromJson(json.decode(source) as Map<String, dynamic>);

  String encode() => json.encode(toJson());
}
