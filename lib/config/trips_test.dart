import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class TripsTest {
  // ทดสอบการดึงข้อมูล trips
  static Future<void> testGetTrips() async {
    print('🗺️ Testing Get Trips API...');

    try {
      print('📡 Sending request to: ${ApiConfig.tripsUrl}');

      final response = await http
          .get(Uri.parse(ApiConfig.tripsUrl), headers: ApiConfig.headers)
          .timeout(ApiConfig.requestTimeout);

      print('\n📊 Response Status: ${response.statusCode}');
      print('📊 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData is List) {
          print('\n✅ Trips API Test PASSED!');
          print('📈 Found ${jsonData.length} trips');

          // แสดงข้อมูลทริปแรก
          if (jsonData.isNotEmpty) {
            final firstTrip = jsonData[0];
            print('\n🎯 Sample Trip Data:');
            print('ID: ${firstTrip['idx']}');
            print('Name: ${firstTrip['name']}');
            print('Country: ${firstTrip['country']}');
            print('Price: ${firstTrip['price']}');
            print('Cover Image: ${firstTrip['coverimage']}');
            print('Detail: ${firstTrip['detail']}');
          }
        } else {
          print('\n⚠️ Response is not a list format');
          print('Response type: ${jsonData.runtimeType}');
        }
      } else {
        print('\n❌ Trips API Test FAILED!');
        print('Status Code: ${response.statusCode}');
      }
    } catch (e) {
      print('\n❌ Trips API Error: $e');
      print('\n🔧 Troubleshooting Tips:');
      print('1. ตรวจสอบว่า server ทำงานอยู่');
      print('2. ตรวจสอบ endpoint /trips');
      print('3. ตรวจสอบ network connection');
    }
  }

  // ทดสอบการดึงข้อมูลทริปตาม ID
  static Future<void> testGetTripById(int tripId) async {
    print('\n🎯 Testing Get Trip by ID: $tripId');

    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.tripsUrl}/$tripId'),
            headers: ApiConfig.headers,
          )
          .timeout(ApiConfig.requestTimeout);

      print('📊 Response Status: ${response.statusCode}');
      print('📊 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final tripData = jsonDecode(response.body);
        print('✅ Trip by ID Test PASSED!');
        print('Trip Name: ${tripData['name']}');
        print('Trip Country: ${tripData['country']}');
      } else {
        print('❌ Trip by ID Test FAILED!');
      }
    } catch (e) {
      print('❌ Trip by ID Error: $e');
    }
  }
}
