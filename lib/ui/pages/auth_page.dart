// Flutter & Third-party imports
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

// Internal imports - Services
import '../../services/app_state.dart';
import '../../repositories/websocket_lotto_repository.dart';

// Internal imports - UI Pages
import 'register_page.dart';

class AuthView extends StatefulWidget {
  const AuthView({super.key});

  @override
  State<AuthView> createState() => _AuthViewState();

  static void logout() {}
}

class _AuthViewState extends State<AuthView> {
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final user = phoneController.text.trim();
    final pass = passwordController.text.trim();

    if (user.isEmpty || pass.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("กรุณากรอกข้อมูลให้ครบ")),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    debugPrint('\n=== FLUTTER LOGIN START ===');
    debugPrint('Username: $user');
    debugPrint('Password length: ${pass.length}');

    final appState = context.read<LottoAppState>();

    try {
      // พยายาม admin login ก่อน
      bool isAdminLogin = false;

      try {
        // ใช้ WebSocketLottoRepository สำหรับ admin login
        if (appState.repo is WebSocketLottoRepository) {
          // Note: Admin login will be handled through regular login method in WebSocket
          debugPrint('WebSocket mode - using member login for admin access');
        }
      } catch (e) {
        debugPrint('Admin login failed, trying member login: $e');
      }

      if (!isAdminLogin) {
        // ใช้ AppState.loginMember() แทน HTTP request แยก
        debugPrint('Attempting member login...');
        
        await appState.loginMember(
          username: user,
          password: pass,
        );
        
        debugPrint('Member login successful!');
      }

      // ตรวจสอบผลลัพธ์และนำทาง
      final currentUser = appState.currentUser;
      if (currentUser != null) {
        debugPrint('Login completed for: ${currentUser.username}');
        debugPrint('User wallet: ${currentUser.wallet}');
        
        if (mounted) {
          // แสดงข้อความสำเร็จ
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('เข้าสู่ระบบสำเร็จ ยินดีต้อนรับ ${currentUser.username}'),
              backgroundColor: Colors.green,
            ),
          );

          // นำทางไปหน้าที่เหมาะสม
          if (currentUser.isOwner) {
            Navigator.pushReplacementNamed(context, '/admin');
          } else {
            Navigator.pushReplacementNamed(context, '/user');
          }
        }
      } else {
        throw Exception('Login failed - no user data received');
      }

    } catch (e) {
      debugPrint('Login error: $e');

      if (mounted) {
        String errorMessage = e.toString();
        
        // ลบ "Exception: " prefix ถ้ามี
        if (errorMessage.startsWith('Exception: ')) {
          errorMessage = errorMessage.substring(11);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("เข้าสู่ระบบไม่สำเร็จ: $errorMessage"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1F2937),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFF60A5FA), Color(0xFF34D399)],
                ).createShader(bounds),
                child: const Text(
                  "SULTAN LOTTO",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "เข้าสู่ระบบ หรือ สมัครสมาชิก",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),

              // Username/Phone Field
              TextField(
                controller: phoneController,
                decoration: InputDecoration(
                  hintText: "เบอร์โทรศัพท์ / username",
                  hintStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: const Color(0xFF111827),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: Color(0xFF3B82F6), width: 2),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 12),

              // Password Field
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: "รหัสผ่าน",
                  hintStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: const Color(0xFF111827),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: Color(0xFF3B82F6), width: 2),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                onSubmitted: (_) => _isLoading ? null : _handleLogin(),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  // LOGIN BUTTON
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isLoading ? null : _handleLogin,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              "เข้าสู่ระบบ",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // REGISTER BUTTON
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isLoading ? null : () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const RegisterView(),
                          ),
                        );
                      },
                      child: const Text(
                        "สมัครสมาชิก",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              
              const Text(
                "หากมีปัญหาในการเข้าสู่ระบบ กรุณาติดต่อแอดมิน",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
