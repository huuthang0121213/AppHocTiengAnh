import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/vocab_provider.dart';
import '../models/vocab_item.dart';
import '../services/tts_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _onlyFavorites = false;

  @override
  void initState() {
    super.initState();
    // Tải dữ liệu từ SQLite khi mở màn hình
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VocabProvider>().loadVocabularies();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatTimestamp(String timestamp) {
    if (timestamp.isEmpty) return '';
    try {
      final dt = DateTime.parse(timestamp);
      return DateFormat('HH:mm - dd/MM/yyyy').format(dt);
    } catch (_) {
      return timestamp;
    }
  }

  void _confirmDeleteAll(BuildContext context, VocabProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Xóa Lịch Sử', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'Bạn có chắc chắn muốn xóa toàn bộ lịch sử từ vựng trong cơ sở dữ liệu SQLite không?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () {
              provider.clearAll();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã làm trống lịch sử từ vựng SQLite!')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Xóa Hết', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vocabProvider = context.watch<VocabProvider>();
    var items = vocabProvider.vocabList;

    if (_onlyFavorites) {
      items = items.where((i) => i.isFavorite).toList();
    }

    final totalCount = vocabProvider.vocabList.length;
    final favoriteCount = vocabProvider.vocabList.where((i) => i.isFavorite).length;

    return Scaffold(
      backgroundColor: const Color(0xFF13131A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E2E),
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.history_edu_rounded, color: Colors.indigoAccent),
            SizedBox(width: 10),
            Text(
              'Lịch Sử Học Tập (SQLite)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
          if (vocabProvider.vocabList.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent),
              tooltip: 'Xóa toàn bộ lịch sử',
              onPressed: () => _confirmDeleteAll(context, vocabProvider),
            ),
        ],
      ),
      body: Column(
        children: [
          // 1. Thẻ Thống Kê Tổng Quan
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2A2B45), Color(0xFF1E1E2E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Tổng Từ Đã Học', '$totalCount', Icons.auto_stories, Colors.cyanAccent),
                Container(width: 1, height: 40, color: Colors.white12),
                _buildStatItem('Từ Yêu Thích', '$favoriteCount', Icons.star_rounded, Colors.amber),
                Container(width: 1, height: 40, color: Colors.white12),
                _buildStatItem('Lưu Trữ', 'SQLite DB', Icons.storage_rounded, Colors.greenAccent),
              ],
            ),
          ),

          // 2. Ô Tìm Kiếm & Bộ Lọc
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => vocabProvider.setSearchQuery(val),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm từ vựng (Anh/Việt)...',
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                      prefixIcon: const Icon(Icons.search, color: Colors.white54, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.white54, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                vocabProvider.setSearchQuery('');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: const Color(0xFF1E1E2E),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FilterChip(
                  label: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, size: 16, color: Colors.amber),
                      SizedBox(width: 4),
                      Text('Yêu thích'),
                    ],
                  ),
                  selected: _onlyFavorites,
                  selectedColor: Colors.amber.withValues(alpha: 0.25),
                  backgroundColor: const Color(0xFF1E1E2E),
                  labelStyle: TextStyle(
                    color: _onlyFavorites ? Colors.amber : Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  side: BorderSide(
                    color: _onlyFavorites ? Colors.amber : Colors.white12,
                  ),
                  onSelected: (val) {
                    setState(() => _onlyFavorites = val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 3. Danh Sách Từ Vựng Đã Học
          Expanded(
            child: vocabProvider.isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.indigoAccent))
                : items.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: items.length,
                        itemBuilder: (ctx, index) {
                          final item = items[index];
                          return _buildVocabCard(item, vocabProvider);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildVocabCard(VocabItem item, VocabProvider provider) {
    return Dismissible(
      key: Key('vocab_${item.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      onDismissed: (_) {
        if (item.id != null) {
          provider.deleteVocabulary(item.id!);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã xóa "${item.word}" khỏi SQLite'),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2E),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: item.isFavorite ? Colors.amber.withValues(alpha: 0.4) : Colors.white10,
          ),
        ),
        child: Row(
          children: [
            // Ảnh thu nhỏ nếu có, nếu không thì hiển thị Icon
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.indigoAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: (item.imagePath != null && File(item.imagePath!).existsSync())
                    ? Image.file(
                        File(item.imagePath!),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.translate, color: Colors.indigoAccent),
                      )
                    : const Icon(Icons.translate, color: Colors.indigoAccent),
              ),
            ),
            const SizedBox(width: 14),

            // Thông tin từ vựng
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          item.word,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.greenAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${(item.confidence * 100).toInt()}%',
                          style: const TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.meaning,
                    style: const TextStyle(
                      color: Color(0xFFFFB74D),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTimestamp(item.timestamp),
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ),

            // Nút nghe phát âm
            IconButton(
              icon: const Icon(Icons.volume_up_rounded, color: Colors.indigoAccent),
              tooltip: 'Nghe phát âm',
              onPressed: () => TTSService.instance.speak(item.word),
            ),

            // Nút yêu thích
            IconButton(
              icon: Icon(
                item.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                color: item.isFavorite ? Colors.amber : Colors.white38,
              ),
              tooltip: item.isFavorite ? 'Bỏ yêu thích' : 'Đánh dấu yêu thích',
              onPressed: () => provider.toggleFavorite(item),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.camera_alt_outlined, size: 64, color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          const Text(
            'Chưa có từ vựng nào được lưu',
            style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          const Text(
            'Hãy chuyển sang tab Camera để quét đồ vật đầu tiên!',
            style: TextStyle(color: Colors.white38, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
