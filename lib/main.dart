import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// 🏗️ INTERNAL IMPORTS - DATA MODELS
import 'models.dart';

// 🔧 INTERNAL IMPORTS - SERVICES & STATE MANAGEMENT
import 'services/app_state.dart';

// 💾 INTERNAL IMPORTS - DATA REPOSITORIES
import 'repositories/websocket_lotto_repository.dart';
import 'repositories/in_memory_repository.dart';
import 'repositories/lotto_repository.dart';

// 🎨 INTERNAL IMPORTS - UI PAGES
import 'ui/pages/admin_page.dart';
import 'ui/pages/auth_page.dart';
import 'ui/pages/member_page.dart';

// ======================================================
// APPLICATION ROUTER & NAVIGATION
// ======================================================
class HomeRouter extends StatelessWidget {
  const HomeRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LottoAppState>(builder: (context, appState, _) {
      // LOADING STATE - แสดงหน้าจอโหลดขณะเริ่มต้นแอป
      if (appState.isLoading) {
        return const Scaffold(
          backgroundColor: Color(0xFF111827),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Color(0xFF10B981)),
                SizedBox(height: 16),
                Text(
                  'กำลังเริ่มต้นแอป...',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        );
      }

      // ERROR STATE - แสดงหน้าจอข้อผิดพลาด
      if (appState.errorMessage != null) {
        return Scaffold(
          backgroundColor: const Color(0xFF111827),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'เกิดข้อผิดพลาด',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    appState.errorMessage!,
                    style: const TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => appState.initializeApp(),
                    child: const Text('ลองใหม่'),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      // ROUTING LOGIC - นำทางตามสถานะผู้ใช้
      if (appState.currentUser == null) {
        return const AuthView(); // 🔐 หน้าล็อกอิน/สมัครสมาชิก
      }

      if (appState.currentUser!.isOwner || appState.currentUser!.role == UserRole.admin) {
        return const AdminPage(); // 👑 หน้าผู้ดูแลระบบ
      }

      return const MemberPage(); // 👤 หน้าสมาชิก
    });
  }
}

// ======================================================
// APPLICATION INITIALIZATION
// ======================================================
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // โหลด .env
  await dotenv.load(fileName: ".env");

  // ตรวจสอบค่า API_BASE_URL
  final apiBaseUrl = dotenv.env['API_BASE_URL'] ?? '';
  if (apiBaseUrl.isEmpty) {
    throw Exception('API_BASE_URL is not defined in .env');
  }
  print('API_BASE_URL = $apiBaseUrl');

  // สร้าง repository
  final LottoRepository repository = WebSocketLottoRepository();

  // 🔹 ทดสอบ WebSocket connection
  if (repository is WebSocketLottoRepository) {
    try {
      await repository.connect();
      print('Connected: ${repository.isConnected}');
    } catch (e) {
      print('WebSocket connection failed: $e');
    }
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LottoAppState(repository)),
      ],
      child: const LottoApp(),
    ),
  );
}

// ======================================================
// MAIN APPLICATION WIDGET
// ======================================================
class LottoApp extends StatelessWidget {
  const LottoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SULTAN L💎TTO',
      theme: ThemeData(
        // 🌙 DARK THEME CONFIGURATION
        colorScheme: const ColorScheme.dark(),
        scaffoldBackgroundColor: const Color(0xFF111827), // Dark background
        textTheme: GoogleFonts.kanitTextTheme(ThemeData.dark().textTheme), // Thai font

        // APP BAR THEME
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1F2937), // Dark card color
          foregroundColor: Colors.white,
        ),

        // BUTTON THEME
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3B82F6), // Blue accent
            foregroundColor: Colors.white,
          ),
        ),
      ),
      home: const HomeRouter(), // เริ่มต้นที่ Router
    );
  }
}
