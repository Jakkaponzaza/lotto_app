// Network Configuration
// เปลี่ยนค่าตรงนี้เมื่อเปลี่ยน network
class NetworkConfig {
  // กำหนด IP address ของเซิร์ฟเวอร์ตรงนี้
  static const String serverIp = '192.168.174.1'; //IP ล่าสุดของฐานข้อมูล
  static const String serverPort = '3000';

  // สร้าง base URL อัตโนมัติ
  static String get baseUrl => 'http://$serverIp:$serverPort';

  // Alternative configurations สำหรับ network ต่างๆ
  static const Map<String, String> networkProfiles = {
    'home': '192.168.1.100',
    'office': '192.168.182.148',
    'mobile_hotspot': '192.168.43.1',
    'localhost': '127.0.0.1',
  };

  // เปลี่ยน network profile ได้ง่ายๆ
  static void switchNetwork(String profileName) {
    if (networkProfiles.containsKey(profileName)) {
      // ในการใช้งานจริง อาจจะต้องใช้ SharedPreferences หรือ config file
      print(
        'Switching to $profileName network: ${networkProfiles[profileName]}',
      );
    }
  }
}
