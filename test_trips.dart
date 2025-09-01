import 'lib/config/trips_test.dart';

void main() async {
  print('🚀 Starting Trips API Tests...\n');

  // ทดสอบการดึงข้อมูลทริปทั้งหมด
  await TripsTest.testGetTrips();

  // รอสักครู่
  await Future.delayed(Duration(seconds: 2));

  // ทดสอบการดึงข้อมูลทริปตาม ID (ใช้ ID 1 เป็นตัวอย่าง)
  await TripsTest.testGetTripById(1);

  print('\n✨ Trips API Tests Completed!');
}
