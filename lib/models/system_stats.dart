// ======================================================
// File: lib/models/system_stats.dart
// Purpose: โมเดลสถิติระบบ
// ======================================================

class SystemStats {
  int totalMembers;
  int ticketsSold;
  int ticketsLeft;
  double totalValue; // Changed from int to double

  SystemStats({
    required this.totalMembers,
    required this.ticketsSold,
    required this.ticketsLeft,
    required this.totalValue,
  });

  Map<String, dynamic> toJson() {
    return {
      'totalMembers': totalMembers,
      'ticketsSold': ticketsSold,
      'ticketsLeft': ticketsLeft,
      'totalValue': totalValue,
    };
  }

  factory SystemStats.fromJson(Map<String, dynamic> json) {
    return SystemStats(
      totalMembers: json['totalMembers'],
      ticketsSold: json['ticketsSold'],
      ticketsLeft: json['ticketsLeft'],
      totalValue: json['totalValue'],
    );
  }
}
