import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // HTTP Client with timeout
  static final http.Client _client = http.Client();

  // Register customer after registration
  static Future<Map<String, dynamic>> registerCustomer({
    required String name,
    required String email,
    required String phone,
    required String password,
    String? address,
    String? image,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse(ApiConfig.customersUrl),
            headers: ApiConfig.headers,
            body: jsonEncode({
              'fullname': name, // เปลี่ยนจาก 'name' เป็น 'fullname'
              'email': email,
              'phone': phone,
              'password': password,
              'address': address ?? '',
              'image': image ?? '',
            }),
          )
          .timeout(ApiConfig.requestTimeout);

      return _handleResponse(response);
    } on SocketException {
      throw Exception('ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้');
    } on HttpException {
      throw Exception('เกิดข้อผิดพลาดในการส่งข้อมูล');
    } catch (e) {
      throw Exception('เกิดข้อผิดพลาด: $e');
    }
  }

  // Get all customers
  static Future<List<dynamic>> getCustomers() async {
    try {
      final response = await _client
          .get(Uri.parse(ApiConfig.customersUrl), headers: ApiConfig.headers)
          .timeout(ApiConfig.requestTimeout);

      final result = _handleResponse(response);
      return result['data'] ?? [];
    } catch (e) {
      throw Exception('ไม่สามารถดึงข้อมูลลูกค้าได้: $e');
    }
  }

  // Get customer by ID
  static Future<Map<String, dynamic>> getCustomerById(int customerId) async {
    try {
      final response = await _client
          .get(
            Uri.parse('${ApiConfig.customersUrl}/$customerId'),
            headers: ApiConfig.headers,
          )
          .timeout(ApiConfig.requestTimeout);

      return _handleResponse(response);
    } catch (e) {
      throw Exception('ไม่สามารถดึงข้อมูลลูกค้าได้: $e');
    }
  }

  // Update customer
  static Future<Map<String, dynamic>> updateCustomer({
    required int customerId,
    required String name,
    required String email,
    required String phone,
    String? address,
    String? image,
  }) async {
    try {
      final response = await _client
          .put(
            Uri.parse('${ApiConfig.customersUrl}/$customerId'),
            headers: ApiConfig.headers,
            body: jsonEncode({
              'fullname': name, // เปลี่ยนจาก 'name' เป็น 'fullname'
              'email': email,
              'phone': phone,
              'address': address ?? '',
              'image': image ?? '',
            }),
          )
          .timeout(ApiConfig.requestTimeout);

      return _handleResponse(response);
    } catch (e) {
      throw Exception('ไม่สามารถอัพเดทข้อมูลลูกค้าได้: $e');
    }
  }

  // Delete customer
  static Future<Map<String, dynamic>> deleteCustomer(int customerId) async {
    try {
      final response = await _client
          .delete(
            Uri.parse('${ApiConfig.customersUrl}/$customerId'),
            headers: ApiConfig.headers,
          )
          .timeout(ApiConfig.requestTimeout);

      return _handleResponse(response);
    } catch (e) {
      throw Exception('ไม่สามารถลบข้อมูลลูกค้าได้: $e');
    }
  }

  // Get all trips
  static Future<List<dynamic>> getTrips() async {
    try {
      final response = await _client
          .get(Uri.parse(ApiConfig.tripsUrl), headers: ApiConfig.headers)
          .timeout(ApiConfig.requestTimeout);

      // ตรวจสอบว่า response เป็น array โดยตรงหรือเป็น object ที่มี data
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonData = jsonDecode(response.body);
        if (jsonData is List) {
          return jsonData;
        } else if (jsonData is Map && jsonData.containsKey('data')) {
          return jsonData['data'] ?? [];
        } else {
          return [];
        }
      } else {
        throw HttpException('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('ไม่สามารถดึงข้อมูลทริปได้: $e');
    }
  }

  // Get trip by ID
  static Future<Map<String, dynamic>> getTripById(int tripId) async {
    try {
      final response = await _client
          .get(
            Uri.parse('${ApiConfig.tripsUrl}/$tripId'),
            headers: ApiConfig.headers,
          )
          .timeout(ApiConfig.requestTimeout);

      return _handleResponse(response);
    } catch (e) {
      throw Exception('ไม่สามารถดึงข้อมูลทริปได้: $e');
    }
  }

  // Handle HTTP response
  static Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw HttpException('HTTP ${response.statusCode}: ${response.body}');
    }
  }

  // Login customer
  static Future<Map<String, dynamic>> loginCustomer({
    required String phone,
    required String password,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('${ApiConfig.baseUrl}/customers/login'),
            headers: ApiConfig.headers,
            body: jsonEncode({'phone': phone, 'password': password}),
          )
          .timeout(ApiConfig.requestTimeout);

      return _handleResponse(response);
    } on SocketException {
      throw Exception('ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้');
    } on HttpException {
      throw Exception('เกิดข้อผิดพลาดในการเข้าสู่ระบบ');
    } catch (e) {
      throw Exception('เกิดข้อผิดพลาด: $e');
    }
  }

  // Test connection to API
  static Future<bool> testConnection() async {
    try {
      final response = await _client
          .get(Uri.parse(ApiConfig.baseUrl), headers: ApiConfig.headers)
          .timeout(ApiConfig.connectionTimeout);

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Dispose client
  static void dispose() {
    _client.close();
  }
}
