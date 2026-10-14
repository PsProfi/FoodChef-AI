import 'dart:convert';
import 'recipe.dart';

class MenuPreset {
  final String id;
  final String title;
  final String description;
  final List<Recipe> recipes;
  final DateTime createdAt;

  MenuPreset({
    required this.id,
    required this.title,
    required this.description,
    required this.recipes,
    required this.createdAt,
  });

  factory MenuPreset.fromJson(Map<String, dynamic> json) {
    return MenuPreset(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title'] ?? 'Пресет меню',
      description: json['description'] ?? '',
      recipes: json['recipes'] is List
          ? (json['recipes'] as List)
              .map((r) => Recipe.fromJson(r as Map<String, dynamic>))
              .toList()
          : [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'recipes': recipes.map((r) => r.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  String encode() => jsonEncode(toJson());

  factory MenuPreset.decode(String str) => MenuPreset.fromJson(jsonDecode(str));
}
