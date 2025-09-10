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
    final lower = message.toLowerCase();

    // Primary patterns
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

    // 🔑 Fallback: look for keyword and next number
    final balanceKeywords = ["avl bal", "available balance", "closing bal", "balance", "bal"];
    for (final keyword in balanceKeywords) {
      final idx = lower.indexOf(keyword);
      if (idx != -1) {
        final substring = message.substring(idx);
        final numberRegex = RegExp(r'(?:inr|rs\.?|₹)?\s*([\d,]+\.\d+|[\d,]+)', caseSensitive: false);
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
    } catch (e) {
      return null;
    }
  }


}
