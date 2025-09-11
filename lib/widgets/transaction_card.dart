import 'package:flutter/material.dart';
import '../models/expense.dart';

class TransactionCard extends StatelessWidget {
  final Expense e;
  final String formattedDate;

  const TransactionCard({
    super.key,
    required this.e,
    required this.formattedDate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Amount + Category
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "₹${e.amount.toStringAsFixed(2)}",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
                Text(
                  e.category,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // 🔹 Date & Time
            Text(
              formattedDate,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            // 🔹 Extracted Name
            Text(
              _extractName(e.title),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            // 🔹 Balance (calculated)
            Text(
              _extractBalance(e.title),
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Extract name after "to"
  String _extractName(String message) {
    final regex = RegExp(r'to\s+([A-Za-z0-9 ]+)', caseSensitive: false);
    final match = regex.firstMatch(message);
    if (match != null) {
      return match.group(1)?.trim() ?? "Unknown";
    }
    return "Unknown";
  }

  /// Extract available balance
  String _extractBalance(String message) {
    final lower = message.toLowerCase();

    final patterns = <RegExp>[
      RegExp(
        r'(?:avl|avail(?:able)?)\s*bal(?:ance)?[^\d]*(?:is\s*)?(?:inr|rs\.?|₹)?\s*([\d,]+\.\d+|[\d,]+)',
        caseSensitive: false,
      ),
      RegExp(
        r'available\s+balance[^\d]*(?:is\s*)?(?:inr|rs\.?|₹)?\s*([\d,]+\.\d+|[\d,]+)',
        caseSensitive: false,
      ),
      RegExp(
        r'\b(?:bal|balance)\b[^\d]*(?:is\s*)?(?:inr|rs\.?|₹)?\s*([\d,]+\.\d+|[\d,]+)',
        caseSensitive: false,
      ),
    ];

    for (final p in patterns) {
      final m = p.firstMatch(message);
      if (m != null) {
        final raw = m.group(1)!;
        final normalized = _normalizeAmountString(raw);
        if (normalized != null) return "Available Balance: ₹$normalized";
      }
    }

    final balanceKeywords = [
      "avl bal",
      "available balance",
      "closing bal",
      "balance",
      "bal"
    ];
    for (final keyword in balanceKeywords) {
      final idx = lower.indexOf(keyword);
      if (idx != -1) {
        final substring = message.substring(idx);
        final numberRegex = RegExp(
          r'(?:inr|rs\.?|₹)?\s*([\d,]+\.\d+|[\d,]+)',
          caseSensitive: false,
        );
        final match = numberRegex.firstMatch(substring);
        if (match != null) {
          final raw = match.group(1)!;
          final normalized = _normalizeAmountString(raw);
          if (normalized != null) return "Available Balance: ₹$normalized";
        }
      }
    }

    return "Balance not found";
  }

  String? _normalizeAmountString(String raw) {
    try {
      final cleaned = raw.replaceAll(',', '').trim();
      return double.parse(cleaned).toStringAsFixed(2);
    } catch (_) {
      return null;
    }
  }
}
