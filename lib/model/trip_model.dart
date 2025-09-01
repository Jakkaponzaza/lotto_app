import 'dart:convert';
import '../ui_1/showtrip_ui.dart';

// Trip Model สำหรับข้อมูลจาก API
class Trip {
  final int idx;
  final String name;
  final String detail;
  final String price;
  final String coverimage;
  final String country;

  Trip({
    required this.idx,
    required this.name,
    required this.detail,
    required this.price,
    required this.coverimage,
    required this.country,
  });

  factory Trip.fromJson(Map<String, dynamic> json) => Trip(
    idx: json["idx"] ?? 0,
    name: json["name"] ?? "",
    detail: json["detail"] ?? "",
    price: json["price"]?.toString() ?? "0",
    coverimage: json["coverimage"] ?? "",
    country: json["country"] ?? "",
  );

  Map<String, dynamic> toJson() => {
    "idx": idx,
    "name": name,
    "detail": detail,
    "price": price,
    "coverimage": coverimage,
    "country": country,
  };

  // แปลงเป็น TripData สำหรับ UI เดิม
  TripData toTripData() {
    return TripData(
      id: idx,
      country: country,
      city: name,
      duration: _extractDuration(detail),
      price: _formatPrice(price),
      imagePath: coverimage,
      category: _getCategory(country),
      detail: detail,
    );
  }

  String _extractDuration(String detail) {
    // พยายามหาข้อมูลระยะเวลาจาก detail
    if (detail.contains('วัน')) {
      final match = RegExp(r'(\d+)\s*วัน').firstMatch(detail);
      if (match != null) {
        return 'ระยะเวลา ${match.group(1)} วัน';
      }
    }
    return 'ระยะเวลา 7 วัน'; // default
  }

  String _formatPrice(String price) {
    try {
      final numPrice = double.parse(price);
      return '${numPrice.toStringAsFixed(0)} บาท';
    } catch (e) {
      return '$price บาท';
    }
  }

  String _getCategory(String country) {
    final countryLower = country.toLowerCase();
    if (countryLower.contains('ญี่ปุ่น') ||
        countryLower.contains('japan') ||
        countryLower.contains('เกาหลี') ||
        countryLower.contains('korea') ||
        countryLower.contains('จีน') ||
        countryLower.contains('china')) {
      return 'เอเซีย';
    } else if (countryLower.contains('อเมริกา') ||
        countryLower.contains('america') ||
        countryLower.contains('usa') ||
        countryLower.contains('แคนาดา') ||
        countryLower.contains('canada')) {
      return 'อเมริกา';
    } else if (countryLower.contains('ฝรั่งเศส') ||
        countryLower.contains('france') ||
        countryLower.contains('อิตาลี') ||
        countryLower.contains('italy') ||
        countryLower.contains('เยอรมนี') ||
        countryLower.contains('germany')) {
      return 'ยุโรป';
    } else if (countryLower.contains('ไทย') ||
        countryLower.contains('thailand') ||
        countryLower.contains('มาเลเซีย') ||
        countryLower.contains('malaysia') ||
        countryLower.contains('สิงคโปร์') ||
        countryLower.contains('singapore')) {
      return 'อาเซียน';
    }
    return 'อื่นๆ';
  }
}

// TripData class อยู่ใน showtrip_ui.dart แล้ว

// Helper functions
List<Trip> tripsFromJson(String str) {
  final jsonData = json.decode(str);
  if (jsonData is List) {
    return List<Trip>.from(jsonData.map((x) => Trip.fromJson(x)));
  }
  return [];
}

String tripsToJson(List<Trip> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));
