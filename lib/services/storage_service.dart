import 'package:shared_preferences/shared_preferences.dart';
import '../models/menu_preset.dart';
import '../models/recipe.dart';
import '../models/shopping_item.dart';

class StorageService {
  static const String _apiKeyKey = 'gemini_api_key';
  static const String _favoritesKey = 'favorite_recipes';
  static const String _menuPresetsKey = 'menu_presets';
  static const String _shoppingListKey = 'shopping_list';
  static const String _recipeHistoryKey = 'recipe_history';

  static Future<void> saveApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyKey, apiKey.trim());
  }

  static Future<String?> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_apiKeyKey);
  }

  // Favorites
  static Future<List<Recipe>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? favStrings = prefs.getStringList(_favoritesKey);
    if (favStrings == null) return [];
    
    return favStrings.map((s) {
      final recipe = Recipe.decode(s);
      recipe.isFavorite = true;
      return recipe;
    }).toList();
  }

  static Future<bool> isFavorite(String recipeId) async {
    final favs = await getFavorites();
    return favs.any((r) => r.id == recipeId);
  }

  static Future<void> toggleFavorite(Recipe recipe) async {
    final prefs = await SharedPreferences.getInstance();
    final favs = await getFavorites();
    
    final existingIndex = favs.indexWhere((r) => r.id == recipe.id);
    if (existingIndex >= 0) {
      favs.removeAt(existingIndex);
      recipe.isFavorite = false;
    } else {
      recipe.isFavorite = true;
      favs.add(recipe);
    }

    final encodedList = favs.map((r) => r.encode()).toList();
    await prefs.setStringList(_favoritesKey, encodedList);
  }

  // Menu Presets
  static Future<List<MenuPreset>> getMenuPresets() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? presetStrings = prefs.getStringList(_menuPresetsKey);
    if (presetStrings == null) return [];
    return presetStrings.map((s) => MenuPreset.decode(s)).toList();
  }

  static Future<void> saveMenuPreset(MenuPreset preset) async {
    final prefs = await SharedPreferences.getInstance();
    final presets = await getMenuPresets();
    presets.removeWhere((p) => p.id == preset.id);
    presets.insert(0, preset);

    final encodedList = presets.map((p) => p.encode()).toList();
    await prefs.setStringList(_menuPresetsKey, encodedList);
  }

  static Future<void> deleteMenuPreset(String presetId) async {
    final prefs = await SharedPreferences.getInstance();
    final presets = await getMenuPresets();
    presets.removeWhere((p) => p.id == presetId);

    final encodedList = presets.map((p) => p.encode()).toList();
    await prefs.setStringList(_menuPresetsKey, encodedList);
  }

  // Shopping List
  static Future<List<ShoppingItem>> getShoppingList() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? items = prefs.getStringList(_shoppingListKey);
    if (items == null) return [];
    return items.map((s) => ShoppingItem.decode(s)).toList();
  }

  static Future<void> saveShoppingList(List<ShoppingItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final encodedList = items.map((i) => i.encode()).toList();
    await prefs.setStringList(_shoppingListKey, encodedList);
  }

  static Future<void> addShoppingItems(List<ShoppingItem> newItems) async {
    final current = await getShoppingList();
    for (final item in newItems) {
      if (!current.any((c) => c.name.toLowerCase() == item.name.toLowerCase())) {
        current.add(item);
      }
    }
    await saveShoppingList(current);
  }

  // Recipe History
  static Future<List<Recipe>> getRecipeHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? strings = prefs.getStringList(_recipeHistoryKey);
    if (strings == null) return [];

    final favorites = await getFavorites();
    return strings.map((s) {
      final recipe = Recipe.decode(s);
      recipe.isFavorite = favorites.any((f) => f.id == recipe.id);
      return recipe;
    }).toList();
  }

  static Future<void> addRecipesToHistory(List<Recipe> newRecipes) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getRecipeHistory();

    for (final recipe in newRecipes) {
      current.removeWhere((r) => r.id == recipe.id);
      current.insert(0, recipe);
    }

    if (current.length > 50) {
      current.removeRange(50, current.length);
    }

    final encodedList = current.map((r) => r.encode()).toList();
    await prefs.setStringList(_recipeHistoryKey, encodedList);
  }

  static Future<void> clearRecipeHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recipeHistoryKey);
  }
}
