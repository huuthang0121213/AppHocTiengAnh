import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/vocab_provider.dart';
import 'screens/camera_screen.dart';
import 'screens/history_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khóa hướng màn hình dọc để trải nghiệm camera tốt nhất
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Cấu hình thanh trạng thái (StatusBar) trong suốt
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const VocabLensApp());
}

class VocabLensApp extends StatelessWidget {
  const VocabLensApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => VocabProvider()..loadVocabularies(),
        ),
      ],
      child: MaterialApp(
        title: 'VocabLens',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.dark,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF13131A),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF6366F1),
            secondary: Color(0xFF06B6D4),
            surface: Color(0xFF1E1E2E),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1E1E2E),
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: false,
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Color(0xFF1E1E2E),
            selectedItemColor: Color(0xFF6366F1),
            unselectedItemColor: Colors.white38,
            type: BottomNavigationBarType.fixed,
            elevation: 12,
          ),
        ),
        home: const MainNavigationScreen(),
      ),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    CameraScreen(),
    HistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final vocabCount = context.watch<VocabProvider>().vocabList.length;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2E),
          border: Border(
            top: BorderSide(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.camera_alt_outlined),
              activeIcon: Icon(Icons.camera_alt_rounded),
              label: 'Quét Camera',
            ),
            BottomNavigationBarItem(
              icon: Badge(
                isLabelVisible: vocabCount > 0,
                label: Text(
                  '$vocabCount',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
                backgroundColor: const Color(0xFF6366F1),
                child: const Icon(Icons.auto_stories_outlined),
              ),
              activeIcon: Badge(
                isLabelVisible: vocabCount > 0,
                label: Text(
                  '$vocabCount',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
                backgroundColor: const Color(0xFF6366F1),
                child: const Icon(Icons.auto_stories_rounded),
              ),
              label: 'Từ Vựng (SQLite)',
            ),
          ],
        ),
      ),
    );
  }
}
