import 'package:image_picker/image_picker.dart';

final ImagePicker picker = ImagePicker();

Future<void> pickImage() async {
  // 1. Стандартний виклик галереї
  final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,  // Обмеження ширини Full HD
      maxHeight: 1080, // Обмеження висоти
      imageQuality: 85 // Компресія до 85% значно економить ОЗП
  );


  if (image != null) {
    // Обробити фото
  }
}

// 2. Обов'язковий метод для Android на випадок знищення MainActivity
Future<void> retrieveLostData() async {
  final LostDataResponse response = await picker.retrieveLostData();
  if (response.isEmpty) return;

  if (response.file != null) {
    // Ось ваше «втрачене» фото, яке повернулося після вильоту/перезапуску
    final XFile file = response.file!;
    // Обробити файл
  } else {
    // Тут можна обробити код помилки, якщо щось пішло не так
    print(response.exception);
  }
}
