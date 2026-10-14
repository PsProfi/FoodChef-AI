import 'dart:convert';

class Recipe {
  final String id;
  final String title;
  final String description;
  final int prepTimeMinutes;
  final String difficulty;
  final List<String> ingredients;
  final List<String> steps;
  final String? calories;
  bool isFavorite;

  Recipe({
    required this.id,
    required this.title,
    required this.description,
    required this.prepTimeMinutes,
    required this.difficulty,
    required this.ingredients,
    required this.steps,
    this.calories,
    this.isFavorite = false,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] ?? '${DateTime.now().millisecondsSinceEpoch}_${(json['title'] ?? '').toString().hashCode}',
      title: json['title'] ?? json['name'] ?? 'Без назви',
      description: json['description'] ?? '',
      prepTimeMinutes: json['prep_time_minutes'] is int
          ? json['prep_time_minutes']
          : int.tryParse(json['prep_time_minutes']?.toString() ?? '20') ?? 20,
      difficulty: json['difficulty'] ?? 'Середнє',
      ingredients: json['ingredients_list'] is List
          ? (json['ingredients_list'] as List).map((e) => e.toString()).toList()
          : (json['ingredients'] is List
              ? (json['ingredients'] as List).map((e) => e.toString()).toList()
              : []),
      steps: json['steps'] is List
          ? (json['steps'] as List).map((e) => e.toString()).toList()
          : [],
      calories: json['calories']?.toString(),
      isFavorite: json['isFavorite'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'prep_time_minutes': prepTimeMinutes,
      'difficulty': difficulty,
      'ingredients_list': ingredients,
      'steps': steps,
      'calories': calories,
      'isFavorite': isFavorite,
    };
  }

  String encode() => jsonEncode(toJson());

  factory Recipe.decode(String str) => Recipe.fromJson(jsonDecode(str));
}
