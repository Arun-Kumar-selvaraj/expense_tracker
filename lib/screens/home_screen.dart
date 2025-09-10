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
      body: Column(
        children: [
          // ✅ Visible button for Uncategorized transactions
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.category_outlined),
                label: const Text('Uncategorized Transactions'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const UncategorizedScreen()),
                  );
                },
              ),
            ),
          ),

          // List of Expenses
          Expanded(
            child: list.isEmpty
                ? const Center(child: Text('No expenses yet'))
                : ListView.builder(
              itemCount: list.length,
              itemBuilder: (_, i) {
                final e = list[i];
                final formattedDate =
                DateFormat("dd MMM yyyy, hh:mm a").format(e.dateTime);

                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🔹 Top row: Amount (left) + Category (right)
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
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
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "sim_btn",
            child: const Icon(Icons.sms),
            tooltip: "Simulate SMS",
            onPressed: () {
              sms.simulateMessage(
                context,
                "INR 500 spent at Zomatoo on 02-Sep. Avl bal: INR 12,345.50 to Arun",
              );
            },
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  /// Extract name after "to" (basic parsing)
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
    final regex = RegExp(
        r'Avl bal[: ]+INR\s?([0-9,]+\.?[0-9]*)',
        caseSensitive: false);
    final match = regex.firstMatch(message);
    if (match != null) {
      return "Available Balance: ₹${match.group(1)}";
    }
    return "Balance not found";
  }
}
