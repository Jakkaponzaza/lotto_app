// ======================================================
// 🎫 LOTTO TICKET DATA MODEL
// ======================================================
// File: lib/models/ticket.dart
// Purpose: โมเดลข้อมูลตั๋วลอตโต้
// Features:
//   - Ticket identification and numbering
//   - Status tracking (available/sold/claimed)
//   - Owner assignment
// ======================================================

class Ticket {
  // 🔑 TICKET IDENTIFICATION
  String id;           // Unique ticket ID
  String number;       // 6-digit ticket number
  
  // 💰 TICKET PRICING
  double price;        // Ticket price (matches database DECIMAL(10,2))
  
  // 📊 TICKET STATUS
  String status;       // 'available' | 'sold' | 'claimed'
  String? ownerId;     // null before purchase

  Ticket({
    required this.id,
    required this.number,
    required this.price,
    this.status = 'available',
    this.ownerId,
  });

  // ======================================================
  // 📤 JSON SERIALIZATION METHODS
  // ======================================================
  
  /// Converts ticket object to JSON for API communication
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'number': number,
      'price': price,
      'status': status,
      'owner_id': ownerId,
    };
  }

  /// Creates ticket object from JSON data (API response)
  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id']?.toString() ?? '', // แปลง int เป็น String
      number: json['number']?.toString() ?? '', // แปลง int เป็น String ถ้าจำเป็น
      price: (json['price'] is num ? (json['price'] as num).toDouble() : 80.0),
      status: json['status']?.toString() ?? 'available',
      ownerId: json['owner_id']?.toString(), // แปลง int เป็น String ถ้าจำเป็น
    );
  }
}
