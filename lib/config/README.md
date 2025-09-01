# API Configuration Guide

## การตั้งค่า API สำหรับเชื่อมต่อกับ Backend

### ไฟล์ที่สำคัญ:

1. **network_config.dart** - จัดการ IP address และ network profiles
2. **api_config.dart** - กำหนด endpoints และ headers
3. **api_service.dart** - service สำหรับเรียก API

### การเปลี่ยน Network:

#### วิธีที่ 1: แก้ไข IP address ใน network_config.dart
```dart
static const String serverIp = '192.168.182.148'; // เปลี่ยนตรงนี้
```

#### วิธีที่ 2: ใช้ Network Profiles
```dart
// ใน network_config.dart มี profiles ให้เลือก:
static const Map<String, String> networkProfiles = {
  'home': '192.168.1.100',
  'office': '192.168.182.148', 
  'mobile_hotspot': '192.168.43.1',
  'localhost': '127.0.0.1',
};
```

### การใช้งาน API Service:

#### ลงทะเบียนลูกค้าใหม่:
```dart
import '../config/api_service.dart';

final result = await ApiService.registerCustomer(
  name: 'ชื่อลูกค้า',
  email: 'email@example.com',
  phone: '0812345678',
  address: 'ที่อยู่',
);
```

#### ดึงข้อมูลลูกค้าทั้งหมด:
```dart
final customers = await ApiService.getCustomers();
```

#### ดึงข้อมูลลูกค้าตาม ID:
```dart
final customer = await ApiService.getCustomerById(1);
```

### API Endpoints ที่รองรับ:

- `POST /customers` - สร้างลูกค้าใหม่
- `GET /customers` - ดึงข้อมูลลูกค้าทั้งหมด
- `GET /customers/:id` - ดึงข้อมูลลูกค้าตาม ID
- `PUT /customers/:id` - อัพเดทข้อมูลลูกค้า
- `DELETE /customers/:id` - ลบข้อมูลลูกค้า
- `GET /trips` - ดึงข้อมูลทริปทั้งหมด

### การจัดการ Error:

API Service จะ throw Exception เมื่อเกิดข้อผิดพลาด:
- `SocketException` - ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์
- `HttpException` - HTTP error codes
- `TimeoutException` - Request timeout

### ตัวอย่างการใช้งานใน Widget:

ดูตัวอย่างใน `lib/pages/register_example.dart`