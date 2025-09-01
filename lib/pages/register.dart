import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_ui_1/ui_1/register_ui.dart';
import '../config/api_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController fullnameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String errorMessage = '';
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return RegisterUI(
      fullnameController: fullnameController,
      phoneController: phoneController,
      emailController: emailController,
      passwordController: passwordController,
      onRegister: register,
      errorMessage: errorMessage,
      isLoading: isLoading,
    );
  }

  Future<void> register() async {
    // Validate input fields
    if (fullnameController.text.isEmpty ||
        phoneController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty) {
      setState(() {
        errorMessage = 'กรุณากรอกข้อมูลให้ครบถ้วน';
      });
      return;
    }

    // Validate email format
    if (!RegExp(
      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
    ).hasMatch(emailController.text.trim())) {
      setState(() {
        errorMessage = 'รูปแบบอีเมลไม่ถูกต้อง';
      });
      return;
    }

    // Validate phone format (basic check)
    if (phoneController.text.trim().isEmpty) {
      setState(() {
        errorMessage = 'กรุณากรอกหมายเลขโทรศัพท์';
      });
      return;
    }

    // Validate password length
    if (passwordController.text.trim().length < 6) {
      setState(() {
        errorMessage = 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
      });
      return;
    }

    setState(() {
      errorMessage = '';
      isLoading = true;
    });

    try {
      log('Starting registration process...');
      log('Name: ${fullnameController.text.trim()}');
      log('Email: ${emailController.text.trim()}');
      log('Phone: ${phoneController.text.trim()}');

      // เรียก API เพื่อส่งข้อมูลไป /customers endpoint
      final result = await ApiService.registerCustomer(
        name: fullnameController.text.trim(),
        email: emailController.text.trim(),
        phone: phoneController.text.trim(),
        password: passwordController.text.trim(),
        address: '', // ไม่มีช่องที่อยู่ในฟอร์มนี้
        image: '', // ไม่มีช่องรูปภาพในฟอร์มลงทะเบียน
      );

      log('Registration successful: $result');

      if (mounted) {
        // แสดงผลสำเร็จพร้อม Customer ID
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ลงทะเบียนสำเร็จ! ยินดีต้อนรับ ${fullnameController.text.trim()}',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // ล้างข้อมูลในฟอร์ม
        fullnameController.clear();
        phoneController.clear();
        emailController.clear();
        passwordController.clear();

        // กลับไปหน้า login
        Navigator.pop(context);
      }
    } catch (e) {
      log('Registration Error: $e');

      if (mounted) {
        setState(() {
          errorMessage = 'เกิดข้อผิดพลาด: $e';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ลงทะเบียนไม่สำเร็จ: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }
}
