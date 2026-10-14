import 'dart:convert';

class ShoppingItem {
  final String id;
  final String name;
  bool isBought;
  final String? category;

  ShoppingItem({
    required this.id,
    required this.name,
    this.isBought = false,
    this.category,
  });

  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    return ShoppingItem(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name'] ?? '',
      isBought: json['isBought'] ?? false,
      category: json['category'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isBought': isBought,
      'category': category,
    };
  }

  String encode() => jsonEncode(toJson());

  factory ShoppingItem.decode(String str) => ShoppingItem.fromJson(jsonDecode(str));
}
