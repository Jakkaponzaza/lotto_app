import 'network_config.dart';

class ApiConfig {
  // Base URL สำหรับ API (ใช้จาก NetworkConfig)
  static String get baseUrl => NetworkConfig.baseUrl;

  // API Endpoints
  static const String customersEndpoint = '/customers';
  static const String tripsEndpoint = '/trips';
  static const String bookingsEndpoint = '/bookings';

  // Full API URLs
  static String get customersUrl => '$baseUrl$customersEndpoint';
  static String get tripsUrl => '$baseUrl$tripsEndpoint';
  static String get bookingsUrl => '$baseUrl$bookingsEndpoint';

  // Headers สำหรับ API requests
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Timeout settings
  static const Duration requestTimeout = Duration(seconds: 30);
  static const Duration connectionTimeout = Duration(seconds: 10);
}
