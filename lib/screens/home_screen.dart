import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../providers/expense_provider.dart';
import '../services/sms_service.dart';
import 'analytics_screen.dart';
import 'uncategorized_screen.dart';
import 'all_transactions_screen.dart';
import '../widgets/transaction_card.dart';

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

    // Category data for donut chart
    Map<String, double> categoryData = {};
    for (var e in list) {
      categoryData[e.category] =
          (categoryData[e.category] ?? 0) + e.amount;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Expense Tracker"),
        actions: [
          // 🔔 Bell icon behaves like uncategorized FAB
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                tooltip: "View Uncategorized",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const UncategorizedScreen()),
                  );
                },
              ),
              if (uncategorizedCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
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
          )
        ],
      ),

      body: list.isEmpty
          ? const Center(child: Text('No expenses yet'))
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Donut Chart Section
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AnalyticsScreen()),
                );
              },
              child: SizedBox(
                height: 250,
                child: PieChart(
                  PieChartData(
                    sections: categoryData.entries.map((entry) {
                      final percent = (entry.value /
                          categoryData.values.fold(
                              0.0, (a, b) => a + b) *
                          100)
                          .toStringAsFixed(1);
                      return PieChartSectionData(
                        value: entry.value,
                        title: "$percent%",
                        radius: 100,
                        titleStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    }).toList(),
                    sectionsSpace: 2,
                    centerSpaceRadius: 50,
                  ),
                ),
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                "Recent Transactions",
                style:
                TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            // 🔹 5 Recent Transactions using TransactionCard
            ...list.take(5).map((e) {
              final formattedDate =
              DateFormat("dd MMM yyyy, hh:mm a").format(e.dateTime);
              return TransactionCard(e: e, formattedDate: formattedDate);
            }),

            // 🔹 See All button
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                child: const Text("See All"),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AllTransactionsScreen()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
