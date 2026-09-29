import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/vocab_item.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('vocablens.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const textNullable = 'TEXT';
    const realType = 'REAL NOT NULL';
    const intType = 'INTEGER NOT NULL DEFAULT 0';

    await db.execute('''
      CREATE TABLE vocabularies (
        id $idType,
        word $textType,
        meaning $textNullable,
        confidence $realType,
        timestamp $textType,
        isFavorite $intType,
        imagePath $textNullable
      )
    ''');
  }

  /// Thêm một từ vựng mới vào database
  Future<int> insertVocab(VocabItem item) async {
    final db = await database;
    return await db.insert(
      'vocabularies',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Lấy toàn bộ danh sách từ vựng đã lưu (mới nhất lên đầu)
  Future<List<VocabItem>> getAllVocabularies() async {
    final db = await database;
    final result = await db.query(
      'vocabularies',
      orderBy: 'id DESC',
    );
    return result.map((json) => VocabItem.fromMap(json)).toList();
  }

  /// Cập nhật trạng thái yêu thích
  Future<int> toggleFavorite(int id, bool isFavorite) async {
    final db = await database;
    return await db.update(
      'vocabularies',
      {'isFavorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Xóa một từ vựng theo ID
  Future<int> deleteVocab(int id) async {
    final db = await database;
    return await db.delete(
      'vocabularies',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Xóa toàn bộ lịch sử từ vựng
  Future<int> deleteAll() async {
    final db = await database;
    return await db.delete('vocabularies');
  }

  /// Đóng kết nối database khi cần
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
