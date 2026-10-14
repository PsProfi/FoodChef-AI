import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/file_import_service.dart';
import '../services/storage_service.dart';
import '../widgets/api_key_dialog.dart';
import 'analysis_screen.dart';
import 'favorites_screen.dart';
import 'menu_presets_screen.dart';
import 'recipe_history_screen.dart';
import 'shopping_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _checkLostData();
  }

  Future<void> _checkLostData() async {
    try {
      final LostDataResponse response = await _picker.retrieveLostData();
      if (response.isEmpty) {
        return;
      }
      if (response.file != null) {
        final XFile image = response.file!;
        final Uint8List imageBytes = await image.readAsBytes();
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AnalysisScreen(imageBytes: imageBytes),
          ),
        );
      } else if (response.exception != null) {
        debugPrint('Lost data exception: ${response.exception}');
      }
    } catch (e) {
      debugPrint('Error retrieving lost data: $e');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        final Uint8List imageBytes = await image.readAsBytes();
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AnalysisScreen(imageBytes: imageBytes),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Помилка при виборі зображення: $e')),
      );
    }
  }

  Future<void> _importFromFile() async {
    try {
      final ingredients = await FileImportService.pickAndImportIngredients();
      if (ingredients != null && ingredients.isNotEmpty) {
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AnalysisScreen(initialIngredients: ingredients),
          ),
        );
      } else if (ingredients != null && ingredients.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Файл не містить інгредієнтів.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Помилка при імпорті файлу: $e')),
      );
    }
  }

  void _showManualIngredientsDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Введіть інгредієнти'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Наприклад: яйця, помідори, сир, масло...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Скасувати'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                final list = text
                    .split(RegExp(r'[,;\n]'))
                    .map((s) => s.trim())
                    .where((s) => s.isNotEmpty)
                    .toList();
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AnalysisScreen(initialIngredients: list),
                  ),
                );
              }
            },
            child: const Text('Далі'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Text(' SmartChef AI 👨‍🍳', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined, color: Colors.deepOrange),
            tooltip: 'Що купити',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ShoppingListScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.favorite_rounded, color: Colors.redAccent),
            tooltip: 'Улюблені рецепти',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FavoritesScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepOrange[400]!, Colors.orange[700]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepOrange.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Що сьогодні приготувати?',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Зробіть фото продуктів у холодильнику, і ШІ запропонує найкращі рецепти!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Оберіть спосіб введення:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Action Card: Camera
            _ActionTile(
              icon: Icons.camera_alt_rounded,
              iconColor: Colors.deepOrange,
              title: 'Сфотографувати продукти',
              subtitle: 'Зробити фото холодильника або столу',
              onTap: () => _pickImage(ImageSource.camera),
            ),
            const SizedBox(height: 10),

            // Action Card: Gallery
            _ActionTile(
              icon: Icons.photo_library_rounded,
              iconColor: Colors.blueAccent,
              title: 'Обрати з галереї',
              subtitle: 'Завантажити готове фото продуктів',
              onTap: () => _pickImage(ImageSource.gallery),
            ),
            const SizedBox(height: 10),

            // Action Card: File Import
            _ActionTile(
              icon: Icons.file_upload_rounded,
              iconColor: Colors.purple,
              title: 'Імпортувати список файлом',
              subtitle: 'Завантажити .txt, .csv або .json з інгредієнтами',
              onTap: _importFromFile,
            ),
            const SizedBox(height: 10),

            // Action Card: Manual Input
            _ActionTile(
              icon: Icons.edit_note_rounded,
              iconColor: Colors.green,
              title: 'Ввести продукти вручну',
              subtitle: 'Написати список наявних інгредієнтів',
              onTap: _showManualIngredientsDialog,
            ),

            const SizedBox(height: 24),

            const Text(
              'Планування та Покупки:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Menu Presets Tile
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.deepOrange,
                  child: Icon(Icons.restaurant_menu_rounded, color: Colors.white),
                ),
                title: const Text(
                  'Пресети меню',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('Меню на тиждень, фітнес або свято'),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const MenuPresetsScreen()),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            // Shopping List Tile
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.teal,
                  child: Icon(Icons.shopping_cart_outlined, color: Colors.white),
                ),
                title: const Text(
                  'Список "Що купити"',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('Список продуктів до покупки'),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const ShoppingListScreen()),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            // Saved recipes quick button
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.redAccent,
                  child: Icon(Icons.favorite_rounded, color: Colors.white),
                ),
                title: const Text(
                  'Улюблені рецепти',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('Переглянути збережені страви'),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const FavoritesScreen()),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            // Recipe History quick button
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.indigo,
                  child: Icon(Icons.history_rounded, color: Colors.white),
                ),
                title: const Text(
                  'Історія згенерованих рецептів',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('Усі рецепти, створені ШІ раніше'),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RecipeHistoryScreen()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
