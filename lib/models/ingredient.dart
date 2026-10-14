class Ingredient {
  final String name;
  bool isSelected;

  Ingredient({
    required this.name,
    this.isSelected = true,
  });

  factory Ingredient.fromJson(dynamic json) {
    if (json is String) {
      return Ingredient(name: json);
    } else if (json is Map<String, dynamic>) {
      return Ingredient(
        name: json['name'] ?? json['ingredient'] ?? '',
        isSelected: json['isSelected'] ?? true,
      );
    }
    return Ingredient(name: json.toString());
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'isSelected': isSelected,
    };
  }
}
