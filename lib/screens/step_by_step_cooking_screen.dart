import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/recipe.dart';
import '../services/ai_service.dart';
import '../services/storage_service.dart';
import '../widgets/api_key_dialog.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final Uint8List? imageBytes;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.imageBytes,
  });
}

class StepByStepCookingScreen extends StatefulWidget {
  final Recipe recipe;

  const StepByStepCookingScreen({super.key, required this.recipe});

  @override
  State<StepByStepCookingScreen> createState() => _StepByStepCookingScreenState();
}

class _StepByStepCookingScreenState extends State<StepByStepCookingScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  ChatSession? _chatSession;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    final apiKey = await AIService.resolveApiKey(null);

    final initialGreeting = '''
Привіт! Я твій особистий шеф-кухар 👨‍🍳. Ми готуємо страву **"${widget.recipe.title}"**.

📜 **Інгредієнти та точні грамовки:**
${widget.recipe.ingredients.map((i) => '• $i').join('\n')}

🍳 **Детальні кроки приготування:**
${widget.recipe.steps.asMap().entries.map((e) => '${e.key + 1}. ${e.value}').join('\n')}

Я супроводжуватиму тебе на кожному кроці. Спитай мене про будь-який етап, грамовки, заміну інгредієнтів або надішли фото процесу (наприклад, щоб перевірити готовність чи консистенцію)!
''';

    setState(() {
      _messages.add(ChatMessage(text: initialGreeting, isUser: false));
    });

    try {
      final model = GenerativeModel(
        model: AIService.fallbackModels.first,
        apiKey: apiKey,
      );
      _chatSession = model.startChat(
        history: [
          Content.text(
            'Ти професійний шеф-кухар. Допомагаєш користувачу готувати страву "${widget.recipe.title}". '
            'Опис: ${widget.recipe.description}. '
            'Інгредієнти з грамовками: ${widget.recipe.ingredients.join(', ')}. '
            'Кроки: ${widget.recipe.steps.join(' | ')}. '
            'Відповідай українською мовою, давай чіткі поради по грамовках, часу, температурі та аналізуй надіслані фото процесу приготування.',
          ),
          Content.model([TextPart('Зрозуміло! Я ваш особистий шеф-кухар. Готовий допомагати з грамовками, кроками та відповідати на питання чи аналізувати фото.')]),
        ],
      );
    } catch (e) {
      debugPrint('Error initializing chat session: $e');
    }
  }

  Future<void> _sendMessage({Uint8List? attachedImageBytes}) async {
    final text = _controller.text.trim();
    if (text.isEmpty && attachedImageBytes == null) return;

    _controller.clear();
    setState(() {
      _messages.add(ChatMessage(
        text: text.isEmpty ? '📷 [Надіслано фото на перевірку шефу]' : text,
        isUser: true,
        imageBytes: attachedImageBytes,
      ));
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      final apiKey = await AIService.resolveApiKey(null);

      if (_chatSession == null) {
        final model = GenerativeModel(
          model: AIService.fallbackModels.first,
          apiKey: apiKey,
        );
        _chatSession = model.startChat(
          history: [
            Content.text(
              'Ти професійний шеф-кухар. Допомагаєш користувачу готувати страву "${widget.recipe.title}". '
              'Опис: ${widget.recipe.description}. '
              'Інгредієнти з грамовками: ${widget.recipe.ingredients.join(', ')}. '
              'Кроки: ${widget.recipe.steps.join(' | ')}. '
              'Відповідай українською мовою, давай чіткі поради по грамовках, часу, температурі та аналізуй надіслані фото процесу приготування.',
            ),
            Content.model([TextPart('Зрозуміло! Я ваш особистий шеф-кухар. Готовий допомагати з грамовками, кроками та відповідати на питання чи аналізувати фото.')]),
          ],
        );
      }

      String aiResponseText = '';

      final parts = <Part>[];
      if (text.isNotEmpty) {
        parts.add(TextPart(text));
      } else {
        parts.add(TextPart('Оціни цей момент приготування по фото, чи все роблю правильно?'));
      }
      if (attachedImageBytes != null) {
        parts.add(DataPart('image/jpeg', attachedImageBytes));
      }

      final response = await _chatSession!.sendMessage(Content.multi(parts));
      aiResponseText = response.text ?? 'Не вдалося отримати відповідь.';
      } else {
        aiResponseText = 'Шеф на зв\'язку! Чудова робота, продовжуй за рецептом.';
      }

      setState(() {
        _isLoading = false;
        _messages.add(ChatMessage(text: aiResponseText, isUser: false));
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _messages.add(ChatMessage(
          text: 'Помилка зв’язку з шефом: $e',
          isUser: false,
        ));
      });
      _scrollToBottom();
    }
  }

  Future<void> _pickAndSendImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        await _sendMessage(attachedImageBytes: bytes);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка вибору фото: $e')),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('👨‍🍳 Шеф-чат: ${widget.recipe.title}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return Align(
                  alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.8,
                    ),
                    decoration: BoxDecoration(
                      color: msg.isUser ? Colors.deepOrange[100] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(16).copyWith(
                        bottomRight: msg.isUser ? const Radius.circular(0) : null,
                        bottomLeft: !msg.isUser ? const Radius.circular(0) : null,
                      ),
                      border: Border.all(
                        color: msg.isUser ? Colors.deepOrange[300]! : Colors.grey[300]!,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (msg.imageBytes != null) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(
                              msg.imageBytes!,
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        Text(
                          msg.text,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black87,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.deepOrange),
                  ),
                  SizedBox(width: 8),
                  Text('Шеф думає...', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.camera_alt_rounded, color: Colors.deepOrange),
                    tooltip: 'Зробити фото процесу',
                    onPressed: () => _pickAndSendImage(ImageSource.camera),
                  ),
                  IconButton(
                    icon: const Icon(Icons.photo_library_rounded, color: Colors.blueAccent),
                    tooltip: 'Обрати фото з галереї',
                    onPressed: () => _pickAndSendImage(ImageSource.gallery),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Запитати шефа (напр., скільки часу тушкувати?)...',
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.deepOrange),
                    onPressed: () => _sendMessage(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
