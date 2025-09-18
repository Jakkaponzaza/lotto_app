// ======================================================
// File: lib/core/utils.dart
// Purpose: Utility functions สำหรับระบบลอตโต้
// ======================================================

import 'dart:math';
import '../models/ticket.dart';
import 'constants.dart';

class LottoUtils {
  /// สร้างตั๋วลอตโต้แบบสุ่ม
  static List<Ticket> generateTickets({int total = 200}) {
    final rnd = Random();
    final set = <String>{};

    while (set.length < total) {
      final n = (rnd.nextInt(900000) + 100000).toString();
      set.add(n.padLeft(6, '0'));
    }

    final list = set.toList()..sort();
    return List.generate(
      list.length,
      (i) => Ticket(
        id: 't$i', 
        number: list[i],
        price: LottoConstants.lottoPrice.toDouble(),
      ),
    );
  }

  /// สร้าง ID แบบสุ่ม
  static String generateId(String prefix) {
    return prefix +
        DateTime.now().millisecondsSinceEpoch.toString() +
        Random().nextInt(1000).toString();
  }
}
