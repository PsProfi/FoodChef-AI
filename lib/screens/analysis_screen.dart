import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../models/ingredient.dart';
import '../models/recipe.dart';
import '../services/ai_service.dart';
import '../services/storage_service.dart';
import '../widgets/api_key_dialog.dart';
import 'recipe_list_screen.dart';

class AnalysisScreen extends StatefulWidget {
  final Uint8List? imageBytes;
  final List<String>? initialIngredients;

  const AnalysisScreen({
    super.key,
    this.imageBytes,
    this.initialIngredients,
  });

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  bool _isLoading = false;
  String _loadingMessage = 'Аналізуємо продукти на фото...';
  String? _errorMessage;

  List<Ingredient> _ingredients = [];
  List<Recipe> _recipes = [];

  String _selectedMealType = 'Будь-який';
  final List<String> _mealTypes = [
    'Будь-який',
    'Сніданок',
    'Обід',
    'Вечеря',
    'Десерт',
  ];

  final TextEditingController _addIngredientController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialIngredients != null && widget.initialIngredients!.isNotEmpty) {
      _ingredients = widget.initialIngredients!
          .map((name) => Ingredient(name: name))
          .toList();
    } else if (widget.imageBytes != null) {
      _startImageAnalysis();
    }
  }

  @override
  void dispose() {
    _addIngredientController.dispose();
    super.dispose();
  }

  Future<void> _startImageAnalysis() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _loadingMessage = 'Аналізуємо фото за допомогою ШІ...';
    });

    try {
      final result = await AIService.analyzeFoodImage(
        imageBytes: widget.imageBytes!,
      );

      await StorageService.addRecipesToHistory(result.recipes);

      setState(() {
        _ingredients = result.ingredients;
        _recipes = result.recipes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Помилка аналізу: ${e.toString()}';
      });
    }
  }

  Future<void> _generateRecipes() async {
    final activeIngredients = _ingredients
        .where((i) => i.isSelected)
        .map((i) => i.name)
        .toList();

    if (activeIngredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Оберіть хоча б один інгредієнт для генерації рецептів'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _loadingMessage = 'Шукаємо найсмачніші рецепти...';
      _errorMessage = null;
    });

    try {
      final recipes = await AIService.generateRecipesFromIngredients(
        ingredients: activeIngredients,
        mealType: _selectedMealType,
      );

      await StorageService.addRecipesToHistory(recipes);

      setState(() {
        _recipes = recipes;
        _isLoading = false;
      });

      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RecipeListScreen(recipes: _recipes),
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Помилка генерації рецептів: ${e.toString()}';
      });
    }
  }

  void _addNewIngredient() {
    final name = _addIngredientController.text.trim();
    if (name.isNotEmpty) {
      setState(() {
        _ingredients.add(Ingredient(name: name));
        _addIngredientController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Результат аналізу'),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SpinKitFadingCube(
                    color: Colors.deepOrange,
                    size: 50.0,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _loadingMessage,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Це може зайняти кілька секунд',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.red[900]),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (widget.imageBytes != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.memory(
                        widget.imageBytes!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  const Text(
                    '📍 Знайдені інгредієнти:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _ingredients.map((ing) {
                      return FilterChip(
                        label: Text(ing.name),
                        selected: ing.isSelected,
                        selectedColor: Colors.deepOrange[100],
                        checkmarkColor: Colors.deepOrange,
                        onSelected: (bool selected) {
                          setState(() {
                            ing.isSelected = selected;
                          });
                        },
                        onDeleted: () {
                          setState(() {
                            _ingredients.remove(ing);
                          });
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _addIngredientController,
                          decoration: const InputDecoration(
                            hintText: 'Додати інгредієнт вручну...',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onSubmitted: (_) => _addNewIngredient(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: _addNewIngredient,
                        icon: const Icon(Icons.add),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  const Text(
                    '⚙️ Опції рецептів:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedMealType,
                    decoration: const InputDecoration(
                      labelText: 'Тип прийому їжі',
                      border: OutlineInputBorder(),
                    ),
                    items: _mealTypes
                        .map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedMealType = val;
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _generateRecipes,
                      icon: const Icon(Icons.auto_awesome_rounded),
                      label: const Text(
                        'Згенерувати рецепти за допомогою ШІ',
                        style: TextStyle(fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  if (_recipes.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Готові рецепти:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    RecipeListScreen(recipes: _recipes),
                              ),
                            );
                          },
                          child: const Text('Переглянути всі'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
