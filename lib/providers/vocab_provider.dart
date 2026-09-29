import 'package:flutter/foundation.dart';
import '../models/vocab_item.dart';
import '../services/database_helper.dart';

class VocabProvider with ChangeNotifier {
  List<VocabItem> _vocabList = [];
  bool _isLoading = false;
  String _searchQuery = '';

  List<VocabItem> get vocabList {
    if (_searchQuery.trim().isEmpty) {
      return _vocabList;
    }
    final query = _searchQuery.toLowerCase();
    return _vocabList.where((item) {
      return item.word.toLowerCase().contains(query) ||
          item.meaning.toLowerCase().contains(query);
    }).toList();
  }

  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;

  /// Tải toàn bộ danh sách từ SQLite khi khởi động
  Future<void> loadVocabularies() async {
    _isLoading = true;
    notifyListeners();

    try {
      _vocabList = await DatabaseHelper.instance.getAllVocabularies();
    } catch (e) {
      debugPrint('Error loading vocabularies: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Thêm từ vựng mới vào SQLite và cập nhật danh sách
  Future<void> addVocabulary(VocabItem item) async {
    try {
      final id = await DatabaseHelper.instance.insertVocab(item);
      final newItem = item.copyWith(id: id);
      _vocabList.insert(0, newItem);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding vocabulary: $e');
    }
  }

  /// Chuyển đổi trạng thái yêu thích
  Future<void> toggleFavorite(VocabItem item) async {
    if (item.id == null) return;
    final newStatus = !item.isFavorite;

    try {
      await DatabaseHelper.instance.toggleFavorite(item.id!, newStatus);
      final index = _vocabList.indexWhere((element) => element.id == item.id);
      if (index != -1) {
        _vocabList[index] = item.copyWith(isFavorite: newStatus);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
    }
  }

  /// Xóa một từ vựng
  Future<void> deleteVocabulary(int id) async {
    try {
      await DatabaseHelper.instance.deleteVocab(id);
      _vocabList.removeWhere((item) => item.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting vocabulary: $e');
    }
  }

  /// Xóa toàn bộ lịch sử
  Future<void> clearAll() async {
    try {
      await DatabaseHelper.instance.deleteAll();
      _vocabList.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing vocabularies: $e');
    }
  }

  /// Cập nhật từ khóa tìm kiếm
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }
}
