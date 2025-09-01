import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('🧪 Testing API Connection...\n');

  final baseUrl = 'http://192.168.182.148:3000';

  try {
    // ทดสอบ /trips endpoint
    print('📡 Testing /trips endpoint...');
    final response = await http
        .get(
          Uri.parse('$baseUrl/trips'),
          headers: {'Content-Type': 'application/json'},
        )
        .timeout(Duration(seconds: 10));

    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        print('✅ Found ${data.length} trips');
        if (data.isNotEmpty) {
          print('Sample trip: ${data[0]}');
        }
      } else {
        print('⚠️ Response is not a list: ${data.runtimeType}');
      }
    } else {
      print('❌ API Error: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ Connection Error: $e');
    print('\n💡 Suggestions:');
    print('1. Check if server is running at $baseUrl');
    print('2. Check network connection');
    print('3. Check firewall settings');
  }
}
