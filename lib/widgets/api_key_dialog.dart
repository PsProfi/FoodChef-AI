import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class ApiKeyDialog extends StatefulWidget {
  final String? initialKey;

  const ApiKeyDialog({super.key, this.initialKey});

  static Future<String?> show(BuildContext context) async {
    final currentKey = await StorageService.getApiKey();
    if (!context.mounted) return null;
    return showDialog<String>(
      context: context,
      barrierDismissible: currentKey != null && currentKey.isNotEmpty,
      builder: (context) => ApiKeyDialog(initialKey: currentKey),
    );
  }

  @override
  State<ApiKeyDialog> createState() => _ApiKeyDialogState();
}

class _ApiKeyDialogState extends State<ApiKeyDialog> {
  late final TextEditingController _controller;
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialKey ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() async {
    final key = _controller.text.trim();
    if (key.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Будь ласка, введіть API ключ')),
      );
      return;
    }
    await StorageService.saveApiKey(key);
    if (mounted) {
      Navigator.of(context).pop(key);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.key_rounded, color: Colors.deepOrange),
          SizedBox(width: 8),
          Text('Gemini API Ключ'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Для використання ШІ необхідний безкоштовний ключ Google Gemini API.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              obscureText: _obscureText,
              decoration: InputDecoration(
                labelText: 'Введіть API ключ',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Як отримати безкоштовно:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const Text(
              '1. Перейдіть на aistudio.google.com\n'
              '2. Натисніть "Get API Key"\n'
              '3. Скопіюйте ключ та вставте сюди.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
      actions: [
        if (widget.initialKey != null && widget.initialKey!.isNotEmpty)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Скасувати'),
          ),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepOrange,
            foregroundColor: Colors.white,
          ),
          child: const Text('Зберегти'),
        ),
      ],
    );
  }
}
