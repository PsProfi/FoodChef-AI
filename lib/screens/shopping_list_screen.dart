import 'package:flutter/material.dart';
import '../models/shopping_item.dart';
import '../services/storage_service.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  List<ShoppingItem> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final list = await StorageService.getShoppingList();
    if (mounted) {
      setState(() {
        _items = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleItem(ShoppingItem item) async {
    setState(() {
      item.isBought = !item.isBought;
    });
    await StorageService.saveShoppingList(_items);
  }

  Future<void> _clearBought() async {
    setState(() {
      _items.removeWhere((item) => item.isBought);
    });
    await StorageService.saveShoppingList(_items);
  }

  void _addItemDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Додати продукт до списку'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Наприклад: Молоко 1л, Хліб...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Скасувати'),
          ),
          ElevatedButton(
            onPressed: () async {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                final newItem = ShoppingItem(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: text,
                );
                setState(() {
                  _items.add(newItem);
                });
                await StorageService.saveShoppingList(_items);
                if (context.mounted) Navigator.of(context).pop();
              }
            },
            child: const Text('Додати'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unboughtCount = _items.where((i) => !i.isBought).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('🛒 Що купити'),
        actions: [
          if (_items.any((i) => i.isBought))
            IconButton(
              icon: const Icon(Icons.cleaning_services_rounded),
              tooltip: 'Очистити куплене',
              onPressed: _clearBought,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart_outlined,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      const Text(
                        'Ваш список покупок порожній',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Додавайте товари вручну або генеруйте з пресетів меню!',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      color: Colors.deepOrange.withValues(alpha: 0.1),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Залишилося купити: $unboughtCount з ${_items.length}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.deepOrange,
                            ),
                          ),
                          if (_items.any((i) => i.isBought))
                            TextButton(
                              onPressed: _clearBought,
                              child: const Text('Видалити куплені'),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          return CheckboxListTile(
                            value: item.isBought,
                            activeColor: Colors.deepOrange,
                            title: Text(
                              item.name,
                              style: TextStyle(
                                decoration: item.isBought
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                                color:
                                    item.isBought ? Colors.grey : Colors.black87,
                              ),
                            ),
                            subtitle: item.category != null
                                ? Text(item.category!,
                                    style: const TextStyle(fontSize: 11))
                                : null,
                            onChanged: (_) => _toggleItem(item),
                            secondary: IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.grey),
                              onPressed: () async {
                                setState(() {
                                  _items.removeAt(index);
                                });
                                await StorageService.saveShoppingList(_items);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addItemDialog,
        icon: const Icon(Icons.add),
        label: const Text('Додати товар'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
    );
  }
}
