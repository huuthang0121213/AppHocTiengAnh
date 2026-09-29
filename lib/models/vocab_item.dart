class VocabItem {
  final int? id;
  final String word;
  final String meaning;
  final double confidence;
  final String timestamp;
  final bool isFavorite;
  final String? imagePath;

  VocabItem({
    this.id,
    required this.word,
    required this.meaning,
    required this.confidence,
    required this.timestamp,
    this.isFavorite = false,
    this.imagePath,
  });

  /// Chuyển đổi sang Map để lưu vào SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'word': word,
      'meaning': meaning,
      'confidence': confidence,
      'timestamp': timestamp,
      'isFavorite': isFavorite ? 1 : 0,
      'imagePath': imagePath,
    };
  }

  /// Khởi tạo VocabItem từ dữ liệu dòng trong SQLite
  factory VocabItem.fromMap(Map<String, dynamic> map) {
    return VocabItem(
      id: map['id'] as int?,
      word: map['word'] as String? ?? '',
      meaning: map['meaning'] as String? ?? '',
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0.0,
      timestamp: map['timestamp'] as String? ?? '',
      isFavorite: (map['isFavorite'] as int? ?? 0) == 1,
      imagePath: map['imagePath'] as String?,
    );
  }

  /// Tạo bản sao có cập nhật trường
  VocabItem copyWith({
    int? id,
    String? word,
    String? meaning,
    double? confidence,
    String? timestamp,
    bool? isFavorite,
    String? imagePath,
  }) {
    return VocabItem(
      id: id ?? this.id,
      word: word ?? this.word,
      meaning: meaning ?? this.meaning,
      confidence: confidence ?? this.confidence,
      timestamp: timestamp ?? this.timestamp,
      isFavorite: isFavorite ?? this.isFavorite,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}
