import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';

class FileImportService {
  static Future<List<String>?> pickAndImportIngredients() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt', 'csv', 'json'],
    );

    if (result == null || result.isEmpty) {
      return null;
    }

    final file = result.first;
    String content = '';

// Переконуємося, що метод, де лежить цей код, має маркер async
    Future<String?> readFileContent(PlatformFile file) async {
      String content;

      try {
        // 1. Спробуємо прочитати байти напряму через новий метод readAsBytes()
        final bytes = await file.readAsBytes();
        content = utf8.decode(bytes);
      } catch (e) {
        // 2. Якщо робота з байтами не вдалася (або ви на мобільній платформі, де краще читати через шлях)
        if (file.path != null) {
          content = await File(file.path!).readAsString();
        } else {
          return null;
        }
      }

      return content;
    }

    return parseIngredientsFromText(content, file.extension);
  }

  static List<String> parseIngredientsFromText(String content, String? extension) {
    List<String> ingredients = [];

    if (extension == 'json') {
      try {
        final decoded = jsonDecode(content);
        if (decoded is List) {
          return decoded.map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList();
        } else if (decoded is Map && decoded['ingredients'] is List) {
          return (decoded['ingredients'] as List).map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList();
        }
      } catch (_) {}
    }

    // Default line-by-line / CSV parsing
    final lines = content.split(RegExp(r'[\r\n;,]'));
    for (var line in lines) {
      final trimmed = line.replaceAll(RegExp(r'^[•\-\d.\s]+'), '').trim();
      if (trimmed.isNotEmpty && trimmed.length < 50) {
        ingredients.add(trimmed);
      }
    }

    return ingredients;
  }
}
