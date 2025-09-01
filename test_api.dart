import 'lib/config/api_test.dart';

void main() async {
  print('🚀 Starting API Tests...\n');

  // ทดสอบการเชื่อมต่อ API
  await ApiTest.testApiConnection();

  // รอสักครู่
  await Future.delayed(Duration(seconds: 2));

  // ทดสอบการลงทะเบียน
  await ApiTest.testRegisterCustomer();

  print('\n✨ API Tests Completed!');
}
