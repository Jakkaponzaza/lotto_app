// ======================================================
//  SYSTEM CONSTANTS & CONFIGURATION
// ======================================================
// File: lib/core/constants.dart
// Purpose: ค่าคงที่และค่าตั้งค่าของระบบลอตโต้
// Categories:
//   - Business Logic Constants
//   - API Endpoints
//   - UI Theme Colors
// ======================================================

class LottoConstants {
  // BUSINESS LOGIC CONSTANTS
  static const int lottoPrice = 80;        // ราคาตั๋วลอตโต้
  static const int totalTickets = 200;     // จำนวนตั๋วทั้งหมด (≥ 100 ตามสเปค)

  // API ENDPOINTS
  static const String apiOwner = '/api/owner';
  static const String apiLoginMember = '/api/login-member';
  static const String apiLogin = '/api/login';
  static const String apiRegister = '/api/register';
  static const String apiTickets = '/api/tickets';
  static const String apiPurchase = '/api/purchase';
  static const String apiDraw = '/api/draw';
  static const String apiStats = '/api/stats';
  static const String apiReset = '/api/reset';
  static const String apiInitTickets = '/api/init-tickets';

  // UI THEME COLORS
  static const int colorBackground = 0xFF111827;  // Dark background
  static const int colorCard = 0xFF1F2937;        // Card background
  static const int colorAccent = 0xFF3B82F6;      // Primary accent color
}
