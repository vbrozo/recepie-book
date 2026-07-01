import 'dart:convert';

class ShoppingListItem {
  final String id;
  final String name;
  final double? quantity;
  final String? unit;
  final bool isChecked;
  final String? recipeId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ShoppingListItem({
    required this.id,
    required this.name,
    this.quantity,
    this.unit,
    this.isChecked = false,
    this.recipeId,
    required this.createdAt,
    required this.updatedAt,
  });

  ShoppingListItem copyWith({
    String? id,
    String? name,
    double? quantity,
    String? unit,
    bool? isChecked,
    String? recipeId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ShoppingListItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      isChecked: isChecked ?? this.isChecked,
      recipeId: recipeId ?? this.recipeId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ShoppingListItem.fromMap(Map<String, Object?> map) {
    return ShoppingListItem(
      id: map['id'] as String,
      name: map['name'] as String,
      quantity: map['quantity'] as double?,
      unit: map['unit'] as String?,
      isChecked: (map['is_checked'] as int) == 1,
      recipeId: map['recipe_id'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'is_checked': isChecked ? 1 : 0,
      'recipe_id': recipeId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ShoppingListItem.fromJson(Map<String, dynamic> json) {
    return ShoppingListItem(
      id: json['id'] as String,
      name: json['name'] as String,
      quantity: (json['quantity'] as num?)?.toDouble(),
      unit: json['unit'] as String?,
      isChecked: json['is_checked'] as bool? ?? false,
      recipeId: json['recipe_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'is_checked': isChecked,
      'recipe_id': recipeId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static ShoppingListItem decode(String source) =>
      ShoppingListItem.fromJson(json.decode(source) as Map<String, dynamic>);

  String encode() => json.encode(toJson());
}
