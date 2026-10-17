import 'package:flutter/foundation.dart';
import '../models/qr_item.dart';
import '../services/database_service.dart';

class HistoryProvider extends ChangeNotifier {
  List<QrItem> _items = [];
  List<QrItem> get items => _items;

  Future<void> load() async {
    _items = await DatabaseService.instance.getAll();
    notifyListeners();
  }

  Future<void> add(String content, String source) async {
    // Ekama QR eka ekapara wadi parak save wenne nae
    if (_items.isNotEmpty &&
        _items.first.content == content &&
        _items.first.source == source) {
      return;
    }
    final item = QrItem(
      type: QrItem.detectType(content),
      content: content,
      source: source,
      createdAt: DateTime.now(),
    );
    await DatabaseService.instance.insert(item);
    await load();
  }

  Future<void> remove(int id) async {
    await DatabaseService.instance.delete(id);
    await load();
  }

  Future<void> clearAll() async {
    await DatabaseService.instance.clear();
    await load();
  }
}