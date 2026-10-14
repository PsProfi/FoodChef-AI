import 'package:flutter/material.dart';
import '../models/menu_preset.dart';
import '../models/recipe.dart';
import '../models/shopping_item.dart';
import '../services/storage_service.dart';
import 'shopping_list_screen.dart';

class MenuPresetsScreen extends StatefulWidget {
  const MenuPresetsScreen({super.key});

  @override
  State<MenuPresetsScreen> createState() => _MenuPresetsScreenState();
}

class _MenuPresetsScreenState extends State<MenuPresetsScreen> {
  List<MenuPreset> _presets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPresets();
  }

  Future<void> _loadPresets() async {
    final list = await StorageService.getMenuPresets();
    if (mounted) {
      setState(() {
        _presets = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _createNewPreset() async {
    final favorites = await StorageService.getFavorites();
    if (!mounted) return;

    if (favorites.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'У вас немає улюблених рецептів. Спочатку додайте рецепти в улюблені!'),
        ),
      );
      return;
    }

    final titleController = TextEditingController();
    final List<Recipe> selectedRecipes = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Створити пресет меню'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Назва пресету',
                    hintText: 'Наприклад: Меню на вихідні',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Оберіть рецепти для меню:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...favorites.map((recipe) {
                  final isSelected = selectedRecipes.contains(recipe);
                  return CheckboxListTile(
                    title: Text(recipe.title),
                    subtitle: Text('${recipe.prepTimeMinutes} хв'),
                    value: isSelected,
                    onChanged: (val) {
                      setDialogState(() {
                        if (val == true) {
                          selectedRecipes.add(recipe);
                        } else {
                          selectedRecipes.remove(recipe);
                        }
                      });
                    },
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Скасувати'),
            ),
            ElevatedButton(
              onPressed: () async {
                final title = titleController.text.trim();
                if (title.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Введіть назву пресету')),
                  );
                  return;
                }
                if (selectedRecipes.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Оберіть хоча б один рецепт')),
                  );
                  return;
                }

                final newPreset = MenuPreset(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  title: title,
                  description: 'Містить ${selectedRecipes.length} страв',
                  recipes: selectedRecipes,
                  createdAt: DateTime.now(),
                );

                await StorageService.saveMenuPreset(newPreset);
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
                if (mounted) {
                  _loadPresets();
                }
              },
              child: const Text('Зберегти'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateShoppingListFromPreset(MenuPreset preset) async {
    final List<ShoppingItem> items = [];
    for (final recipe in preset.recipes) {
      for (final ing in recipe.ingredients) {
        items.add(
          ShoppingItem(
            id: '${DateTime.now().millisecondsSinceEpoch}_${ing.hashCode}',
            name: ing,
            category: 'Для: ${preset.title}',
          ),
        );
      }
    }

    await StorageService.addShoppingItems(items);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Сформовано список покупок для "${preset.title}" (${items.length} інгр.)'),
        action: SnackBarAction(
          label: 'Переглянути',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ShoppingListScreen()),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📋 Пресети меню'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined, color: Colors.deepOrange),
            tooltip: 'Список покупок',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ShoppingListScreen()),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _presets.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.restaurant_menu_rounded,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      const Text(
                        'У вас немає збережених пресетів меню',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Створюйте власні меню зі збережених рецептів та формуйте списки покупок!',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _createNewPreset,
                        icon: const Icon(Icons.add),
                        label: const Text('Створити пресет меню'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _presets.length,
                  itemBuilder: (context, index) {
                    final preset = _presets[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  preset.title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.grey),
                                  onPressed: () async {
                                    await StorageService.deleteMenuPreset(
                                        preset.id);
                                    _loadPresets();
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Страви в меню (${preset.recipes.length}):',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            ...preset.recipes.map((r) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 2.0),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.check_circle_outline,
                                          size: 16, color: Colors.deepOrange),
                                      const SizedBox(width: 8),
                                      Text(r.title),
                                    ],
                                  ),
                                )),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () =>
                                    _generateShoppingListFromPreset(preset),
                                icon: const Icon(Icons.shopping_cart_checkout),
                                label: const Text('Сформувати "Що купити"'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepOrange,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewPreset,
        icon: const Icon(Icons.add),
        label: const Text('Створити пресет'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
    );
  }
}
