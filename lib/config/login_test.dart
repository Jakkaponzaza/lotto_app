import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class LoginTest {
  // ทดสอบการ login
  static Future<void> testLogin() async {
    print('🔐 Testing Login API...');

    // ข้อมูลทดสอบ (ใช้ข้อมูลที่มีอยู่ใน database)
    final testCredentials = {'phone': '0817399999', 'password': '1111'};

    try {
      print('📡 Sending login request...');
      print('Phone: ${testCredentials['phone']}');
      print('Password: ${testCredentials['password']}');

      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/customers/login'),
            headers: ApiConfig.headers,
            body: jsonEncode(testCredentials),
          )
          .timeout(ApiConfig.requestTimeout);

      print('\n📊 Response Status: ${response.statusCode}');
      print('📊 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        print('\n✅ Login Test PASSED!');
        print('Message: ${result['message']}');
        print('Customer Name: ${result['customer']['fullname']}');
        print('Customer ID: ${result['customer']['idx']}');
        print('Email: ${result['customer']['email']}');
      } else {
        print('\n❌ Login Test FAILED!');
        print('Status Code: ${response.statusCode}');
      }
    } catch (e) {
      print('\n❌ Login Error: $e');
      print('\n🔧 Troubleshooting Tips:');
      print('1. ตรวจสอบว่า server ทำงานอยู่');
      print('2. ตรวจสอบ username/password ที่ใช้ทดสอบ');
      print('3. ตรวจสอบ endpoint /customers/login');
    }
  }

  // ทดสอบ login ด้วยข้อมูลผิด
  static Future<void> testInvalidLogin() async {
    print('\n🔐 Testing Invalid Login...');

    final invalidCredentials = {
      'phone': 'wrong_phone',
      'password': 'wrong_password',
    };

    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/customers/login'),
            headers: ApiConfig.headers,
            body: jsonEncode(invalidCredentials),
          )
          .timeout(ApiConfig.requestTimeout);

      print('📊 Invalid Login Response Status: ${response.statusCode}');
      print('📊 Invalid Login Response Body: ${response.body}');

      if (response.statusCode != 200) {
        print('✅ Invalid login correctly rejected!');
      } else {
        print('❌ Invalid login should have been rejected!');
      }
    } catch (e) {
      print('✅ Invalid login correctly failed: $e');
    }
  }
}
