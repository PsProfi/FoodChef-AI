import 'dart:convert';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/analysis_result.dart';
import '../models/recipe.dart';
import 'storage_service.dart';

class AIService {
  // Вбудований API ключ (замініть на свій реальний ключ Gemini або залиште)
  static const String defaultApiKey = 'ТУТ_ВАШ_API_КЛЮЧ';

  static Future<String> resolveApiKey(String? providedKey) async {
    if (providedKey != null && providedKey.isNotEmpty) {
      return providedKey;
    }
    final storedKey = await StorageService.getApiKey();
    if (storedKey != null && storedKey.isNotEmpty) {
      return storedKey;
    }
    return defaultApiKey;
  }
  static const List<String> fallbackModels = [
    'gemini-1.5-flash',
    'gemini-2.0-flash',
    'gemini-1.5-pro',
    'gemini-3.6-flash'
  ];

  static Map<String, dynamic> _cleanAndParseJson(String rawResponse) {
    String cleaned = rawResponse.trim();
    
    // Remove markdown code fences if present
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }
    cleaned = cleaned.trim();

    try {
      return jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (e) {
      // If parsing failed, try finding first '{' and last '}'
      final firstBrace = cleaned.indexOf('{');
      final lastBrace = cleaned.lastIndexOf('}');
      if (firstBrace != -1 && lastBrace != -1 && lastBrace > firstBrace) {
        final substring = cleaned.substring(firstBrace, lastBrace + 1);
        return jsonDecode(substring) as Map<String, dynamic>;
      }
      rethrow;
    }
  }

  static String _formatErrorMessage(Object error) {
    final str = error.toString().toLowerCase();
    if (str.contains('api_key') || str.contains('invalid api key') || str.contains('unauthorized')) {
      return 'Недійсний Gemini API ключ. Перевірте ключ у налаштуваннях додатка.';
    }
    if (str.contains('quota') || str.contains('resource_exhausted') || str.contains('429')) {
      return 'Перевищено ліміт запитів API. Зачекайте хвилину та спробуйте знову.';
    }
    if (str.contains('not_found') || str.contains('404')) {
      return 'Модель Gemini тимчасово недоступна. Спробуйте пізніше.';
    }
    return 'Помилка ШІ: ${error.toString()}';
  }

  /// Analyzes an image of food/pantry and extracts ingredients + initial recipe ideas.
  static Future<AnalysisResult> analyzeFoodImage({
    required Uint8List imageBytes,
    String? apiKey,
  }) async {
    final key = await resolveApiKey(apiKey);
    Object? lastError;

    for (final modelName in fallbackModels) {
      try {
        final model = GenerativeModel(
          model: modelName,
          apiKey: key,
          generationConfig: GenerationConfig(
            responseMimeType: 'application/json',
          ),
        );

        final prompt = '''
Ви досвідчений шеф-кухар та AI-помічник.
Уважно проаналізуй це зображення та знайди всі видимі продукти харчування, овочі, фрукти, напої та інгредієнти із зазначенням точної ваги та об'єму (грамки, мілілітри, штуки).

Поверни відповідь СУВОРО у форматі JSON українською мовою за такою структурою:

{
  "detected_ingredients": [
    "Яйця — 3 шт (180г)",
    "Помідори — 2 шт (250г)",
    "Сир твердий — 100г"
  ],
  "recipes": [
    {
      "title": "Назва страви",
      "description": "Короткий апетитний опис страви",
      "prep_time_minutes": 25,
      "difficulty": "Легко",
      "ingredients_list": [
        "Куряче філе — 350г",
        "Вершки 20% — 150мл",
        "Оливкова олія — 20мл",
        "Сіль — 5г (1 ч.л.)",
        "Чорний перець — 2г"
      ],
      "steps": [
        "1. Підготуйте та зважте 350г курячого філе, наріжте кубиками 2х2 см.",
        "2. Розігрійте сковороду з 20мл оливкової олії на середньому вогні протягом 2 хвилин.",
        "3. Обсмажуйте курку 7 хвилин до золотистої скоринки при температурі 180°C.",
        "4. Влийте 150мл вершків, додайте 5г солі та 2г перцю, тушкуйте на повільному вогні 10 хвилин під кришкою."
      ],
      "calories": "420 ккал"
    }
  ]
}

Створи від 3 до 5 варіантів страв різної складності, використовуючи знайдені продукти та суворо вказуючи детальні грамовки і пропорції для кожного інгредієнта та кожного кроку.
''';

        final content = [
          Content.multi([
            TextPart(prompt),
            DataPart('image/jpeg', imageBytes),
          ])
        ];

        final response = await model.generateContent(content);
        final text = response.text;

        if (text != null && text.isNotEmpty) {
          final jsonMap = _cleanAndParseJson(text);
          return AnalysisResult.fromJson(jsonMap);
        }
      } catch (e) {
        lastError = e;
      }
    }

    throw Exception(_formatErrorMessage(lastError ?? 'Не вдалося отримати відповідь від ШІ.'));
  }

  /// Generates custom recipes based on a specified list of ingredients and user filters.
  static Future<List<Recipe>> generateRecipesFromIngredients({
    required List<String> ingredients,
    String? apiKey,
    String? mealType,
    String? dietRestrictions,
  }) async {
    final key = await resolveApiKey(apiKey);
    Object? lastError;

    String filterPrompt = '';
    if (mealType != null && mealType != 'Будь-який') {
      filterPrompt += ' Тип страви: $mealType.';
    }
    if (dietRestrictions != null && dietRestrictions.isNotEmpty) {
      filterPrompt += ' Дієтичні обмеження: $dietRestrictions.';
    }

    final prompt = '''
Ви професійний шеф-кухар. Користувач має такі інгредієнти: ${ingredients.join(', ')}.$filterPrompt

Запропонуй 3-5 смачних страв, які можна приготувати з цих продуктів (можна додавати базові спеції, сіль, олію, воду). Усі інгредієнти та кроки приготування повинні містити точні грамовки, об'єми, температуру та час приготування.

Поверни відповідь СУВОРО у форматі JSON українською мовою за такою структурою:
{
  "recipes": [
    {
      "title": "Назва страви",
      "description": "Короткий апетитний опис страви",
      "prep_time_minutes": 30,
      "difficulty": "Середнє",
      "ingredients_list": [
        "Інгредієнт 1 — 300г",
        "Інгредієнт 2 — 150мл",
        "Сіль — 5г"
      ],
      "steps": [
        "1. Підготуйте 300г інгредієнта 1, наріжте соломкою.",
        "2. Додайте 150мл інгредієнта 2 та тушкуйте 15 хвилин на середньому вогні."
      ],
      "calories": "380 ккал"
    }
  ]
}
''';

    for (final modelName in fallbackModels) {
      try {
        final model = GenerativeModel(
          model: modelName,
          apiKey: key,
          generationConfig: GenerationConfig(
            responseMimeType: 'application/json',
          ),
        );

        final response = await model.generateContent([Content.text(prompt)]);
        final text = response.text;

        if (text != null && text.isNotEmpty) {
          final jsonMap = _cleanAndParseJson(text);
          if (jsonMap['recipes'] is List) {
            return (jsonMap['recipes'] as List)
                .map((item) => Recipe.fromJson(item as Map<String, dynamic>))
                .toList();
          }
        }
      } catch (e) {
        lastError = e;
      }
    }

    throw Exception(_formatErrorMessage(lastError ?? 'Не вдалося згенерувати рецепти.'));
  }
}
