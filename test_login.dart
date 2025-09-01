import 'lib/config/login_test.dart';

void main() async {
  print('🚀 Starting Login Tests...\n');

  // ทดสอบ login ด้วยข้อมูลถูกต้อง
  await LoginTest.testLogin();

  // รอสักครู่
  await Future.delayed(Duration(seconds: 2));

  // ทดสอบ login ด้วยข้อมูลผิด
  await LoginTest.testInvalidLogin();

  print('\n✨ Login Tests Completed!');
}
