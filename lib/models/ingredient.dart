import 'dart:convert';

class Ingredient {
  final String id;
  final String recipeId;
  final String name;
  final double? quantity;
  final String? unit;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Ingredient({
    required this.id,
    required this.recipeId,
    required this.name,
    this.quantity,
    this.unit,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  Ingredient copyWith({
    String? id,
    String? recipeId,
    String? name,
    double? quantity,
    String? unit,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Ingredient(
      id: id ?? this.id,
      recipeId: recipeId ?? this.recipeId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Ingredient.fromMap(Map<String, Object?> map) {
    return Ingredient(
      id: map['id'] as String,
      recipeId: map['recipe_id'] as String,
      name: map['name'] as String,
      quantity: map['quantity'] as double?,
      unit: map['unit'] as String?,
      sortOrder: map['sort_order'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'recipe_id': recipeId,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      id: json['id'] as String,
      recipeId: json['recipe_id'] as String,
      name: json['name'] as String,
      quantity: (json['quantity'] as num?)?.toDouble(),
      unit: json['unit'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recipe_id': recipeId,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static Ingredient decode(String source) =>
      Ingredient.fromJson(json.decode(source) as Map<String, dynamic>);

  String encode() => json.encode(toJson());
}
