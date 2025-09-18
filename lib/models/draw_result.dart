// ======================================================
// File: lib/models/draw_result.dart
// Purpose: โมเดลผลการออกรางวัล
// ======================================================

class PrizeItem {
  int tier; // 1..5
  String ticketId; // ผู้ชนะของชั้นนี้
  int amount;
  bool claimed; // สถานะการรับรางวัล

  PrizeItem({
    required this.tier,
    required this.ticketId,
    required this.amount,
    this.claimed = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'tier': tier,
      'ticketId': ticketId,
      'amount': amount,
      'claimed': claimed,
    };
  }

  factory PrizeItem.fromJson(Map<String, dynamic> json) {
    return PrizeItem(
      tier: json['tier'],
      ticketId: json['ticketId'],
      amount: json['amount'],
      claimed: json['claimed'] ?? false,
    );
  }
}

class DrawResult {
  String id;
  String poolType; // 'sold' | 'all'
  DateTime createdAt;
  List<PrizeItem> prizes; // 5 รายการ

  DrawResult({
    required this.id,
    required this.poolType,
    required this.createdAt,
    required this.prizes,
  });

  Map<String, List<String>> get winners {
    final Map<String, List<String>> result = {};
    for (final prize in prizes) {
      final tierName = 'รางวัลที่ ${prize.tier}';
      result[tierName] = [prize.ticketId];
    }
    return result;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'poolType': poolType,
      'createdAt': createdAt.toIso8601String(),
      'prizes': prizes.map((p) => p.toJson()).toList(),
    };
  }

  factory DrawResult.fromJson(Map<String, dynamic> json) {
    return DrawResult(
      id: json['id'],
      poolType: json['poolType'],
      createdAt: DateTime.parse(json['createdAt']),
      prizes:
          (json['prizes'] as List).map((p) => PrizeItem.fromJson(p)).toList(),
    );
  }
}
