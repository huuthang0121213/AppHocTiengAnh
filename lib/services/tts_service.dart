import 'package:flutter_tts/flutter_tts.dart';

class TTSService {
  static final TTSService instance = TTSService._init();
  late FlutterTts _flutterTts;
  bool _isInitialized = false;

  TTSService._init() {
    _initTTS();
  }

  Future<void> _initTTS() async {
    _flutterTts = FlutterTts();
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.45); // Tốc độ vừa phải, dễ nghe học phát âm
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    // Chờ phát âm hoàn tất trước khi gọi tiếp
    await _flutterTts.awaitSpeakCompletion(true);
    _isInitialized = true;
  }

  /// Phát âm một từ hoặc câu tiếng Anh
  Future<void> speak(String text) async {
    if (!_isInitialized) {
      await _initTTS();
    }
    if (text.trim().isEmpty) return;
    await _flutterTts.stop();
    await _flutterTts.speak(text);
  }

  /// Dừng phát âm
  Future<void> stop() async {
    await _flutterTts.stop();
  }
}
