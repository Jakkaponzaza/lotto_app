// ======================================================
// File: lib/ui/widgets/common_widgets.dart
// Purpose: Widget ที่ใช้ร่วมกันในหลายหน้า
// ======================================================

import 'package:flutter/material.dart';

class PrizeInputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;

  const PrizeInputField({
    super.key,
    required this.label,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFF1F2937),
        border: const OutlineInputBorder(),
      ),
      style: const TextStyle(color: Colors.white),
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1F2937),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class LottoTicketWidget extends StatelessWidget {
  final String number;
  final bool isSelected;
  final bool sold;
  final VoidCallback? onTap;

  const LottoTicketWidget({
    super.key,
    required this.number,
    this.isSelected = false,
    this.sold = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    if (sold) {
      bgColor = Colors.grey.shade700;
    } else if (isSelected) {
      bgColor = Colors.green;
    } else {
      bgColor = const Color(0xFF334155);
    }

    return InkWell(
      onTap: sold ? null : onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: Colors.greenAccent, width: 2)
              : null,
        ),
        child: Center(
          child: Text(
            number,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}
