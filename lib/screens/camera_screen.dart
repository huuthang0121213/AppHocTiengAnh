import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import '../services/ml_kit_service.dart';
import '../services/tts_service.dart';
import '../providers/vocab_provider.dart';
import '../models/vocab_item.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  bool _isFlashOn = false;

  late AnimationController _scannerAnimController;

  @override
  void initState() {
    super.initState();
    _scannerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        await _setupCameraController(_cameras[_selectedCameraIndex]);
      }
    } catch (e) {
      debugPrint('Error getting cameras: $e');
    }
  }

  Future<void> _setupCameraController(CameraDescription cameraDescription) async {
    if (_cameraController != null) {
      await _cameraController!.dispose();
    }

    _cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    try {
      if (_isFlashOn) {
        await _cameraController!.setFlashMode(FlashMode.off);
        setState(() => _isFlashOn = false);
      } else {
        await _cameraController!.setFlashMode(FlashMode.torch);
        setState(() => _isFlashOn = true);
      }
    } catch (e) {
      debugPrint('Flash error: $e');
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    setState(() => _isCameraInitialized = false);
    await _setupCameraController(_cameras[_selectedCameraIndex]);
  }

  Future<void> _captureAndScan() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized || _isProcessing) {
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final XFile image = await _cameraController!.takePicture();

      // Sử dụng Google ML Kit nhận diện đồ vật
      final recognizedObjects = await MLKitService.instance.processImageFromFile(image.path);

      if (mounted) {
        setState(() => _isProcessing = false);

        if (recognizedObjects.isNotEmpty) {
          final bestMatch = recognizedObjects.first;

          // Tự động phát âm từ vựng chính
          TTSService.instance.speak(bestMatch.label);

          // Tự động lưu vào CSDL SQLite thông qua VocabProvider
          final vocabItem = VocabItem(
            word: bestMatch.label,
            meaning: bestMatch.vietnamese,
            confidence: bestMatch.confidence,
            timestamp: DateTime.now().toIso8601String(),
            imagePath: image.path,
          );
          context.read<VocabProvider>().addVocabulary(vocabItem);

          // Hiển thị kết quả nhận diện sang trọng
          _showResultSheet(recognizedObjects, image.path);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không nhận diện được vật thể rõ ràng. Vui lòng thử lại!'),
              backgroundColor: Colors.amber,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi chụp ảnh: $e')),
        );
      }
    }
  }

  void _showResultSheet(List<RecognizedObject> objects, String imagePath) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final topObject = objects.first;

        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E2E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Thanh kéo nhỏ
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // Huy hiệu thành công
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle, color: Colors.greenAccent, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Độ chính xác AI: ${(topObject.confidence * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(color: Colors.greenAccent, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.indigoAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '💾 Đã lưu SQLite',
                      style: TextStyle(color: Colors.lightBlueAccent, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Thẻ từ vựng chính
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2A2B45), Color(0xFF1E1F35)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            topObject.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton.filled(
                          onPressed: () => TTSService.instance.speak(topObject.label),
                          icon: const Icon(Icons.volume_up_rounded, color: Colors.white),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.indigoAccent,
                            padding: const EdgeInsets.all(12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      topObject.vietnamese,
                      style: const TextStyle(
                        color: Color(0xFFFFB74D),
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Danh sách các vật thể khác được phát hiện cùng
              if (objects.length > 1) ...[
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Các gợi ý từ vựng liên quan:',
                    style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: objects.skip(1).take(4).map((obj) {
                    return ActionChip(
                      avatar: const Icon(Icons.volume_up, size: 16, color: Colors.indigoAccent),
                      label: Text('${obj.label} (${obj.vietnamese})'),
                      backgroundColor: const Color(0xFF282A36),
                      labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
                      side: const BorderSide(color: Colors.white12),
                      onPressed: () {
                        TTSService.instance.speak(obj.label);
                        // Cho phép lưu nhanh từ phụ vào SQLite
                        final subItem = VocabItem(
                          word: obj.label,
                          meaning: obj.vietnamese,
                          confidence: obj.confidence,
                          timestamp: DateTime.now().toIso8601String(),
                          imagePath: imagePath,
                        );
                        context.read<VocabProvider>().addVocabulary(subItem);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Đã thêm "${obj.label}" vào bộ từ vựng SQLite!'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 24),
              // Nút tiếp tục quét
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Tiếp Tục Quét', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigoAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _scannerAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized || _cameraController == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircularProgressIndicator(color: Colors.indigoAccent),
              SizedBox(height: 16),
              Text(
                'Đang khởi động Camera AI...',
                style: TextStyle(color: Colors.white70, fontSize: 15),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Camera Preview
          CameraPreview(_cameraController!),

          // 2. Kính ngắm Quét (Viewfinder Overlay)
          SafeArea(
            child: Column(
              children: [
                // Thanh công cụ trên cùng (Flash & Đổi Camera)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton.filledTonal(
                        onPressed: _toggleFlash,
                        icon: Icon(_isFlashOn ? Icons.flash_on : Icons.flash_off),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black54,
                          foregroundColor: _isFlashOn ? Colors.amber : Colors.white,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.auto_awesome, color: Colors.indigoAccent, size: 16),
                            SizedBox(width: 6),
                            Text(
                              'VocabLens AI',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      IconButton.filledTonal(
                        onPressed: _switchCamera,
                        icon: const Icon(Icons.flip_camera_ios),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black54,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Khung quét trung tâm (Scanner Target Box)
                Center(
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white24, width: 1.5),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Stack(
                      children: [
                        // 4 góc kính ngắm nổi bật
                        const _ScannerCorners(),

                        // Laser line di chuyển lên xuống
                        AnimatedBuilder(
                          animation: _scannerAnimController,
                          builder: (context, child) {
                            return Positioned(
                              top: 240 * _scannerAnimController.value,
                              left: 10,
                              right: 10,
                              child: Container(
                                height: 2,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Colors.transparent, Colors.cyanAccent, Colors.indigoAccent, Colors.transparent],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.cyanAccent.withValues(alpha: 0.8),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                const Text(
                  'Hướng camera vào vật thể cần học từ vựng',
                  style: TextStyle(color: Colors.white70, fontSize: 13, shadows: [
                    Shadow(color: Colors.black, blurRadius: 4),
                  ]),
                ),

                const Spacer(),

                // 3. Nút Chụp & Quét AI
                Padding(
                  padding: const EdgeInsets.only(bottom: 30),
                  child: Center(
                    child: GestureDetector(
                      onTap: _isProcessing ? null : _captureAndScan,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          color: _isProcessing ? Colors.grey : Colors.indigoAccent,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.indigoAccent.withValues(alpha: 0.5),
                              blurRadius: 16,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: Center(
                          child: _isProcessing
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Icon(Icons.camera_alt, color: Colors.white, size: 36),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerCorners extends StatelessWidget {
  const _ScannerCorners();

  @override
  Widget build(BuildContext context) {
    const cornerSize = 24.0;
    const cornerWidth = 3.5;
    const color = Colors.cyanAccent;

    return Stack(
      children: [
        // Góc trên trái
        Positioned(
          top: 0,
          left: 0,
          child: Container(
            width: cornerSize,
            height: cornerSize,
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: color, width: cornerWidth),
                left: BorderSide(color: color, width: cornerWidth),
              ),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(20)),
            ),
          ),
        ),
        // Góc trên phải
        Positioned(
          top: 0,
          right: 0,
          child: Container(
            width: cornerSize,
            height: cornerSize,
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: color, width: cornerWidth),
                right: BorderSide(color: color, width: cornerWidth),
              ),
              borderRadius: BorderRadius.only(topRight: Radius.circular(20)),
            ),
          ),
        ),
        // Góc dưới trái
        Positioned(
          bottom: 0,
          left: 0,
          child: Container(
            width: cornerSize,
            height: cornerSize,
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: color, width: cornerWidth),
                left: BorderSide(color: color, width: cornerWidth),
              ),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20)),
            ),
          ),
        ),
        // Góc dưới phải
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: cornerSize,
            height: cornerSize,
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: color, width: cornerWidth),
                right: BorderSide(color: color, width: cornerWidth),
              ),
              borderRadius: BorderRadius.only(bottomRight: Radius.circular(20)),
            ),
          ),
        ),
      ],
    );
  }
}
