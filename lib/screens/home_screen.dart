import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/expense_provider.dart';
import '../services/sms_service.dart';
import 'analytics_screen.dart';
import 'uncategorized_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final sms = SmsService();

  @override
  void initState() {
    super.initState();
    sms.start(context);
    Provider.of<ExpenseProvider>(context, listen: false).fetchExpenses();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpenseProvider>(context);
    final list = provider.expenses;

    // Count uncategorized expenses
    final uncategorizedCount =
        list.where((e) => e.category == "Uncategorized").length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.pie_chart),
            tooltip: 'Analytics',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
              );
            },
          ),
        ],
      ),

      // Expense list only (removed top button)
      body: list.isEmpty
          ? const Center(child: Text('No expenses yet'))
          : ListView.builder(
        itemCount: list.length,
        itemBuilder: (_, i) {
          final e = list[i];
          final formattedDate =
          DateFormat("dd MMM yyyy, hh:mm a").format(e.dateTime);

          return Card(
            margin:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
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

                  // 🔹 Extracted Name (after "to")
                  Text(
                    _extractName(e.title),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // 🔹 Available Balance
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
        },
      ),

      // FAB with badge for Uncategorized
      floatingActionButton: Stack(
        clipBehavior: Clip.none,
        children: [
          FloatingActionButton(
            heroTag: "uncat_btn",
            child: const Icon(Icons.category),
            tooltip: "View Uncategorized",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UncategorizedScreen()),
              );
            },
          ),

          if (uncategorizedCount > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 22,
                  minHeight: 22,
                ),
                child: Text(
                  '$uncategorizedCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
    // regex patterns (all case-insensitive)
    final patterns = <RegExp>[
      // Avl bal / Avail bal
      RegExp(r'(?:avl|avail(?:able)?)\s*bal(?:ance)?[:\s\-]*?(?:is\s*)?(?:INR|Rs\.?|₹)?\s*([0-9][0-9,\.]*)',
          caseSensitive: false),
      // Available balance
      RegExp(r'available\s+balance[:\s\-]*?(?:is\s*)?(?:INR|Rs\.?|₹)?\s*([0-9][0-9,\.]*)',
          caseSensitive: false),
      // Balance / Bal
      RegExp(r'\b(?:bal|balance)\b[:\s\-]*?(?:is\s*)?(?:INR|Rs\.?|₹)?\s*([0-9][0-9,\.]*)',
          caseSensitive: false),
      // Generic with currency prefix
      RegExp(r'(?:INR|Rs\.?|₹)\s*([0-9][0-9,\.]*)', caseSensitive: false),
    ];

    for (final p in patterns) {
      final m = p.firstMatch(message);
      if (m != null && m.groupCount >= 1) {
        final raw = m.group(1)!;
        final normalized = _normalizeAmountString(raw);
        if (normalized != null) return "Available Balance: ₹$normalized";
      }
    }

    // fallback: last number-like value
    final genericAmount = RegExp(r'([0-9][0-9,\.]*)');
    final allMatches = genericAmount.allMatches(message).toList();
    if (allMatches.isNotEmpty) {
      final raw = allMatches.last.group(1)!;
      final normalized = _normalizeAmountString(raw);
      if (normalized != null) return "Available Balance: ₹$normalized";
    }

    return "Balance not found";
  }

  String? _normalizeAmountString(String raw) {
    try {
      final cleaned = raw.replaceAll(RegExp(r'[, ]'), '');
      final val = double.parse(cleaned);
      return NumberFormat('#,##0.00', 'en_IN').format(val);
    } catch (_) {
      return null;
    }
  }

}
