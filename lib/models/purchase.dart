// ======================================================
// File: lib/models/purchase.dart
// Purpose: โมเดลการซื้อตั๋ว
// ======================================================

class Purchase {
  String id;
  String userId;
  int totalAmount;
  DateTime createdAt;

  Purchase({
    required this.id,
    required this.userId,
    required this.totalAmount,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'totalAmount': totalAmount,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Purchase.fromJson(Map<String, dynamic> json) {
    return Purchase(
      id: json['id'],
      userId: json['userId'],
      totalAmount: json['totalAmount'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class PurchaseItem {
  String id;
  String purchaseId;
  String ticketId;
  int unitPrice;

  PurchaseItem({
    required this.id,
    required this.purchaseId,
    required this.ticketId,
    required this.unitPrice,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'purchaseId': purchaseId,
      'ticketId': ticketId,
      'unitPrice': unitPrice,
    };
  }

  factory PurchaseItem.fromJson(Map<String, dynamic> json) {
    return PurchaseItem(
      id: json['id'],
      purchaseId: json['purchaseId'],
      ticketId: json['ticketId'],
      unitPrice: json['unitPrice'],
    );
  }
}
