import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_state.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _walletController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _walletController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final wallet = int.tryParse(_walletController.text.trim());
    
    // ตรวจสอบว่า wallet ไม่เป็น null
    if (wallet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณากรอกจำนวนเงินเริ่มต้นให้ถูกต้อง'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      // ใช้ AppState สำหรับการสมัครสมาชิก
      final appState = context.read<LottoAppState>();
      await appState.registerMember(
        username: phone,
        email: email,
        password: password,
        phone: phone,
        initialWallet: wallet,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('สมัครสมาชิกสำเร็จ!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        if (errorMessage.startsWith('Exception: ')) {
          errorMessage = errorMessage.substring(11);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('สมัครสมาชิกไม่สำเร็จ: $errorMessage'),
            backgroundColor: Colors.red,
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
      backgroundColor: Colors.black54,
      body: Center(
        child: SingleChildScrollView(
          child: Material(
            borderRadius: BorderRadius.circular(32),
            color: const Color(0xFF1F2937),
            elevation: 8,
            child: Container(
              padding: const EdgeInsets.all(24),
              width: 400,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.9,
              ),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Close button
                      Align(
                        alignment: Alignment.topRight,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),

                      // Title
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFF34D399), Color(0xFF10B981)],
                        ).createShader(bounds),
                        child: const Text(
                          "สมัครสมาชิก",
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "สร้างบัญชีเพื่อเริ่มใช้งาน",
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                      const SizedBox(height: 24),

                      // Phone field
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("เบอร์โทรศัพท์",
                              style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFF111827),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                    color: Color(0xFF10B981), width: 2),
                              ),
                              hintText: "กรอกเบอร์โทรศัพท์ 10 หลัก",
                              hintStyle: const TextStyle(color: Colors.grey),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'กรุณากรอกเบอร์โทรศัพท์';
                              }
                              if (!RegExp(r'^[0-9]{10}$')
                                  .hasMatch(value.trim())) {
                                return 'เบอร์โทรศัพท์ต้องเป็นตัวเลข 10 หลัก';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Email field
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("อีเมล",
                              style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFF111827),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                    color: Color(0xFF10B981), width: 2),
                              ),
                              hintText: "example@email.com",
                              hintStyle: const TextStyle(color: Colors.grey),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'กรุณากรอกอีเมล';
                              }
                              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$')
                                  .hasMatch(value.trim())) {
                                return 'รูปแบบอีเมลไม่ถูกต้อง';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Password field
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("รหัสผ่าน",
                              style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFF111827),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                    color: Color(0xFF10B981), width: 2),
                              ),
                              hintText: "อย่างน้อย 6 ตัวอักษร",
                              hintStyle: const TextStyle(color: Colors.grey),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'กรุณากรอกรหัสผ่าน';
                              }
                              if (value.trim().length < 6) {
                                return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Initial Wallet field
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("เงินเริ่มต้น",
                              style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _walletController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFF111827),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                    color: Color(0xFF10B981), width: 2),
                              ),
                              hintText: "จำนวนเงินเริ่มต้น",
                              hintStyle: const TextStyle(color: Colors.grey),
                              suffixText: "บาท",
                              suffixStyle: const TextStyle(color: Colors.grey),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'กรุณากรอกจำนวนเงินเริ่มต้น';
                              }
                              final amount = int.tryParse(value.trim());
                              if (amount == null || amount < 0) {
                                return 'กรุณากรอกจำนวนเงินที่ถูกต้อง';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Register button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Text(
                                  "ยืนยันการสมัคร",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
