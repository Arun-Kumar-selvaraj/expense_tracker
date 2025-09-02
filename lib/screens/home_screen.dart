import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../services/sms_service.dart';
import 'analytics_screen.dart';
import 'package:intl/intl.dart';

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
    Provider.of<ExpenseProvider>(context, listen: false).load();
  }

  @override
  Widget build(BuildContext context) {
    final list = Provider.of<ExpenseProvider>(context).expenses;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.pie_chart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
              );
            },
          )
        ],
      ),
      body: list.isEmpty
          ? const Center(child: Text('No expenses yet'))
          : ListView.builder(
        itemCount: list.length,
        itemBuilder: (_, i) {
          final e = list[i];
          final formattedDate =
          DateFormat("dd MMM yyyy, hh:mm a").format(e.date);

          // Extract name from message (after "to" if exists)
          final nameRegex =
          RegExp(r'\bto\s+([A-Za-z\s]+)', caseSensitive: false);
          final match = nameRegex.firstMatch(e.message);
          final receiver =
          match != null ? match.group(1)!.trim() : e.category;

          // Extract balance
          final balanceRegex = RegExp(
              r'bal(?:ance)?\s*(?:is|:)?\s*INR\s?([\d,]+(?:\.\d{1,2})?)',
              caseSensitive: false);
          final balanceMatch = balanceRegex.firstMatch(e.message);
          final balance = balanceMatch != null ? balanceMatch.group(1) : null;

          return Card(
            margin:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Amount + Category Row
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
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Date
                  Text(
                    formattedDate,
                    style: TextStyle(
                        fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 10),

                  // Receiver / Merchant
                  Text(
                    "To: $receiver",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500),
                  ),

                  // Balance
                  if (balance != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      "Balance: ₹$balance",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ]
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.sms),
        onPressed: () {
          sms.simulateMessage(
            context,
            "INR 450.75 spent at Zomato on 02-Sep. Avl bal: INR 12,345.50",
          );
        },
      ),
    );
  }
}
