import 'dart:convert';

class RecipeStep {
  final String id;
  final String recipeId;
  final int stepNumber;
  final String instruction;
  final int? durationMinutes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RecipeStep({
    required this.id,
    required this.recipeId,
    required this.stepNumber,
    required this.instruction,
    this.durationMinutes,
    required this.createdAt,
    required this.updatedAt,
  });

  RecipeStep copyWith({
    String? id,
    String? recipeId,
    int? stepNumber,
    String? instruction,
    int? durationMinutes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RecipeStep(
      id: id ?? this.id,
      recipeId: recipeId ?? this.recipeId,
      stepNumber: stepNumber ?? this.stepNumber,
      instruction: instruction ?? this.instruction,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory RecipeStep.fromMap(Map<String, Object?> map) {
    return RecipeStep(
      id: map['id'] as String,
      recipeId: map['recipe_id'] as String,
      stepNumber: map['step_number'] as int,
      instruction: map['instruction'] as String,
      durationMinutes: map['duration_minutes'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'recipe_id': recipeId,
      'step_number': stepNumber,
      'instruction': instruction,
      'duration_minutes': durationMinutes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory RecipeStep.fromJson(Map<String, dynamic> json) {
    return RecipeStep(
      id: json['id'] as String,
      recipeId: json['recipe_id'] as String,
      stepNumber: json['step_number'] as int,
      instruction: json['instruction'] as String,
      durationMinutes: json['duration_minutes'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recipe_id': recipeId,
      'step_number': stepNumber,
      'instruction': instruction,
      'duration_minutes': durationMinutes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static RecipeStep decode(String source) =>
      RecipeStep.fromJson(json.decode(source) as Map<String, dynamic>);

  String encode() => json.encode(toJson());
}
