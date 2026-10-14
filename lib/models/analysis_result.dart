import 'ingredient.dart';
import 'recipe.dart';

class AnalysisResult {
  final List<Ingredient> ingredients;
  final List<Recipe> recipes;

  AnalysisResult({
    required this.ingredients,
    required this.recipes,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    List<Ingredient> parsedIngredients = [];
    if (json['detected_ingredients'] is List) {
      parsedIngredients = (json['detected_ingredients'] as List)
          .map((item) => Ingredient.fromJson(item))
          .toList();
    } else if (json['ingredients'] is List) {
      parsedIngredients = (json['ingredients'] as List)
          .map((item) => Ingredient.fromJson(item))
          .toList();
    }

    List<Recipe> parsedRecipes = [];
    if (json['recipes'] is List) {
      parsedRecipes = (json['recipes'] as List)
          .map((item) => Recipe.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return AnalysisResult(
      ingredients: parsedIngredients,
      recipes: parsedRecipes,
    );
  }
}
