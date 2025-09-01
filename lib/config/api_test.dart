import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class ApiTest {
  // ทดสอบการเชื่อมต่อ API
  static Future<void> testApiConnection() async {
    print('🔍 Testing API Connection...');
    print('Base URL: ${ApiConfig.baseUrl}');
    print('Customers URL: ${ApiConfig.customersUrl}');

    try {
      // ทดสอบ GET /customers
      print('\n📡 Testing GET /customers...');
      final getResponse = await http
          .get(Uri.parse(ApiConfig.customersUrl), headers: ApiConfig.headers)
          .timeout(ApiConfig.connectionTimeout);

      print('GET Response Status: ${getResponse.statusCode}');
      print('GET Response Body: ${getResponse.body}');

      // ทดสอบ POST /customers
      print('\n📡 Testing POST /customers...');
      final testData = {
        'fullname': 'Test User', // เปลี่ยนจาก 'name' เป็น 'fullname'
        'email': 'test@example.com',
        'phone': '0812345678',
        'address': 'Test Address',
      };

      final postResponse = await http
          .post(
            Uri.parse(ApiConfig.customersUrl),
            headers: ApiConfig.headers,
            body: jsonEncode(testData),
          )
          .timeout(ApiConfig.requestTimeout);

      print('POST Response Status: ${postResponse.statusCode}');
      print('POST Response Body: ${postResponse.body}');

      if (postResponse.statusCode >= 200 && postResponse.statusCode < 300) {
        print('✅ API Connection Test PASSED!');
      } else {
        print('❌ API Connection Test FAILED!');
      }
    } catch (e) {
      print('❌ API Connection Error: $e');
      print('\n🔧 Troubleshooting Tips:');
      print('1. ตรวจสอบว่า server ทำงานอยู่ที่ ${ApiConfig.baseUrl}');
      print('2. ตรวจสอบ IP address ใน network_config.dart');
      print('3. ตรวจสอบ firewall และ network connection');
      print('4. ลองเปิด ${ApiConfig.customersUrl} ใน browser');
    }
  }

  // ทดสอบการส่งข้อมูลจริง
  static Future<void> testRegisterCustomer() async {
    print('\n🧪 Testing Register Customer...');

    try {
      final testCustomer = {
        'fullname': 'ทดสอบ ลงทะเบียน', // เปลี่ยนจาก 'name' เป็น 'fullname'
        'email': 'test.register@example.com',
        'phone': '0987654321',
        'address': 'ที่อยู่ทดสอบ',
      };

      final response = await http
          .post(
            Uri.parse(ApiConfig.customersUrl),
            headers: ApiConfig.headers,
            body: jsonEncode(testCustomer),
          )
          .timeout(ApiConfig.requestTimeout);

      print('Register Response Status: ${response.statusCode}');
      print('Register Response Body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final result = jsonDecode(response.body);
        print('✅ Customer registered successfully!');
        print('Customer ID: ${result['idx']}'); // เปลี่ยนจาก 'id' เป็น 'idx'
      } else {
        print('❌ Registration failed!');
      }
    } catch (e) {
      print('❌ Registration Error: $e');
    }
  }
}
