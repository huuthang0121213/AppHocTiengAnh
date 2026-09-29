import 'dart:io';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

class RecognizedObject {
  final String label;
  final String vietnamese;
  final double confidence;

  RecognizedObject({
    required this.label,
    required this.vietnamese,
    required this.confidence,
  });
}

class MLKitService {
  static final MLKitService instance = MLKitService._init();
  late ImageLabeler _imageLabeler;

  // Từ điển ánh xạ từ vựng AI sang Tiếng Việt phong phú cho đồ án
  static const Map<String, String> _dictionary = {
    // Đồ dùng học tập & Văn phòng
    'backpack': 'Ba lô',
    'bag': 'Túi xách',
    'book': 'Quyển sách',
    'notebook': 'Vở ghi chép',
    'pen': 'Bút bi / Bút mực',
    'pencil': 'Bút chì',
    'paper': 'Tờ giấy',
    'document': 'Tài liệu',
    'scissors': 'Cây kéo',
    'ruler': 'Cây thước kẻ',
    'glasses': 'Mắt kính',
    'sunglasses': 'Kính râm',
    'wallet': 'Cái ví tiền',
    'umbrella': 'Cây dù / Ô',

    // Thiết bị điện tử
    'laptop': 'Máy tính xách tay',
    'computer': 'Máy vi tính',
    'computer keyboard': 'Bàn phím máy tính',
    'computer monitor': 'Màn hình máy tính',
    'computer mouse': 'Chuột máy tính',
    'mouse': 'Chuột máy tính',
    'keyboard': 'Bàn phím',
    'display device': 'Màn hình hiển thị',
    'mobile phone': 'Điện thoại di động',
    'cellular telephone': 'Điện thoại di động',
    'telephone': 'Điện thoại',
    'headphones': 'Tai nghe chụp tai',
    'headset': 'Tai nghe',
    'audio equipment': 'Thiết bị âm thanh',
    'clock': 'Đồng hồ',
    'watch': 'Đồng hồ đeo tay',
    'wrist watch': 'Đồng hồ đeo tay',
    'camera': 'Máy ảnh',
    'remote control': 'Điều khiển từ xa',

    // Đồ gia dụng & Vật dụng thường ngày
    'bottle': 'Chai / Lọ',
    'water bottle': 'Chai nước',
    'cup': 'Cái tách / Cái ly',
    'mug': 'Cốc sứ uống nước',
    'tableware': 'Bộ đồ ăn',
    'chair': 'Cái ghế',
    'table': 'Cái bàn',
    'desk': 'Bàn làm việc / Bàn học',
    'furniture': 'Đồ nội thất',
    'lamp': 'Đèn bàn',
    'lighting': 'Hệ thống đèn',
    'door': 'Cửa ra vào',
    'window': 'Cửa sổ',
    'shoe': 'Chiếc giày',
    'footwear': 'Giày dép',
    'clothing': 'Quần áo',
    'shirt': 'Áo sơ mi',
    'jacket': 'Áo khoác',
    'hat': 'Cái mũ / Nón',

    // Thiên nhiên & Phương tiện
    'flower': 'Bông hoa',
    'plant': 'Cây cối',
    'tree': 'Cây xanh',
    'leaf': 'Chiếc lá',
    'dog': 'Con chó',
    'cat': 'Con mèo',
    'car': 'Xe ô tô',
    'bicycle': 'Xe đạp',
    'motorcycle': 'Xe máy',
    'vehicle': 'Phương tiện giao thông',

    // Thức ăn & Trái cây
    'apple': 'Quả táo',
    'banana': 'Quả chuối',
    'orange': 'Quả cam',
    'fruit': 'Trái cây',
    'food': 'Thức ăn',
    'drink': 'Đồ uống',
    'beverage': 'Nước giải khát',
  };

  MLKitService._init() {
    _initLabeler();
  }

  void _initLabeler() {
    // Ngưỡng độ tin cậy từ 50% trở lên
    final options = ImageLabelerOptions(confidenceThreshold: 0.5);
    _imageLabeler = ImageLabeler(options: options);
  }

  /// Phân tích ảnh từ đường dẫn file (ảnh chụp từ Camera)
  Future<List<RecognizedObject>> processImageFromFile(String filePath) async {
    final inputImage = InputImage.fromFile(File(filePath));
    return await _processInputImage(inputImage);
  }

  /// Xử lý InputImage và trả về danh sách đối tượng nhận diện
  Future<List<RecognizedObject>> _processInputImage(InputImage inputImage) async {
    try {
      final List<ImageLabel> labels = await _imageLabeler.processImage(inputImage);
      final List<RecognizedObject> results = [];

      for (ImageLabel label in labels) {
        final text = label.label.trim();
        final confidence = label.confidence;
        final vietnamese = getVietnameseMeaning(text);

        results.add(RecognizedObject(
          label: _capitalize(text),
          vietnamese: vietnamese,
          confidence: confidence,
        ));
      }

      return results;
    } catch (e) {
      return [];
    }
  }

  /// Tra cứu nghĩa tiếng Việt tương ứng
  String getVietnameseMeaning(String englishWord) {
    final lower = englishWord.toLowerCase().trim();
    if (_dictionary.containsKey(lower)) {
      return _dictionary[lower]!;
    }

    // Tìm kiếm cụm từ khớp một phần nếu chưa có ánh xạ chính xác
    for (var key in _dictionary.keys) {
      if (lower.contains(key) || key.contains(lower)) {
        return _dictionary[key]!;
      }
    }

    return 'Đồ vật / Khái niệm ($englishWord)';
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  /// Giải phóng tài nguyên AI
  void dispose() {
    _imageLabeler.close();
  }
}
