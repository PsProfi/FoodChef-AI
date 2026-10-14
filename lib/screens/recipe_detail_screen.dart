import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../services/storage_service.dart';
import 'step_by_step_cooking_screen.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  late Map<int, bool> _checkedIngredients;

  @override
  void initState() {
    super.initState();
    _checkedIngredients = {
      for (int i = 0; i < widget.recipe.ingredients.length; i++) i: false
    };
    _checkFavoriteStatus();
  }

  void _checkFavoriteStatus() async {
    final isFav = await StorageService.isFavorite(widget.recipe.id);
    if (mounted) {
      setState(() {
        widget.recipe.isFavorite = isFav;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipe.title),
        actions: [
          IconButton(
            icon: Icon(
              widget.recipe.isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: widget.recipe.isFavorite ? Colors.red : null,
            ),
            onPressed: () async {
              await StorageService.toggleFavorite(widget.recipe);
              setState(() {});
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipe Header Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.deepOrange, Colors.orangeAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.recipe.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (widget.recipe.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      widget.recipe.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _DetailHeaderBadge(
                        icon: Icons.timer_outlined,
                        label: '${widget.recipe.prepTimeMinutes} хв',
                      ),
                      _DetailHeaderBadge(
                        icon: Icons.speed_rounded,
                        label: widget.recipe.difficulty,
                      ),
                      if (widget.recipe.calories != null)
                        _DetailHeaderBadge(
                          icon: Icons.local_fire_department_rounded,
                          label: widget.recipe.calories!,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Button for Step-by-Step Cooking Mode
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          StepByStepCookingScreen(recipe: widget.recipe),
                    ),
                  );
                },
                icon: const Icon(Icons.play_circle_fill_rounded),
                label: const Text(
                  'Почати покрокове готування',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
            const SizedBox(height: 24),

            // Ingredients Section
            Text(
              '🥬 Інгредієнти',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  children: List.generate(
                    widget.recipe.ingredients.length,
                    (index) {
                      final item = widget.recipe.ingredients[index];
                      final isChecked = _checkedIngredients[index] ?? false;
                      return CheckboxListTile(
                        value: isChecked,
                        activeColor: Colors.deepOrange,
                        title: Text(
                          item,
                          style: TextStyle(
                            decoration: isChecked
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            color: isChecked ? Colors.grey : Colors.black87,
                          ),
                        ),
                        onChanged: (val) {
                          setState(() {
                            _checkedIngredients[index] = val ?? false;
                          });
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Steps Section
            Text(
              '👨‍🍳 Кроки приготування',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...List.generate(widget.recipe.steps.length, (index) {
              final stepText = widget.recipe.steps[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.deepOrange,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2.0),
                        child: Text(
                          stepText,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _DetailHeaderBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DetailHeaderBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
