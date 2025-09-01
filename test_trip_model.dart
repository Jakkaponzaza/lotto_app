import 'lib/model/trip_model.dart';

void main() {
  print('🧪 Testing Trip Model...\n');

  // ทดสอบการสร้าง Trip object
  final sampleTripJson = {
    "idx": 1,
    "name": "โตเกียว",
    "detail":
        "สัมผัสความงดงามของเมืองหลวงญี่ปุ่น ที่ผสมผสานระหว่างความทันสมัยและประเพณีดั้งเดิม",
    "price": "50000",
    "coverimage": "https://example.com/tokyo.jpg",
    "country": "ประเทศญี่ปุ่น",
  };

  try {
    // สร้าง Trip object จาก JSON
    final trip = Trip.fromJson(sampleTripJson);
    print('✅ Trip object created successfully!');
    print('ID: ${trip.idx}');
    print('Name: ${trip.name}');
    print('Country: ${trip.country}');
    print('Price: ${trip.price}');
    print('Detail: ${trip.detail}');
    print('Cover Image: ${trip.coverimage}');

    // แปลงเป็น TripData
    final tripData = trip.toTripData();
    print('\n✅ TripData conversion successful!');
    print('ID: ${tripData.id}');
    print('City: ${tripData.city}');
    print('Country: ${tripData.country}');
    print('Duration: ${tripData.duration}');
    print('Price: ${tripData.price}');
    print('Category: ${tripData.category}');
    print('Detail: ${tripData.detail}');
    print('Image Path: ${tripData.imagePath}');
  } catch (e) {
    print('❌ Error: $e');
  }

  print('\n✨ Trip Model Test Completed!');
}
