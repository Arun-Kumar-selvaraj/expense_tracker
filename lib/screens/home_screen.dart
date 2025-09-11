import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

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

    // Count uncategorized
    final uncategorizedCount =
        list.where((e) => e.category == "Uncategorized").length;

    // Calculate total spent (exclude income/credited)
    double spent = 0;
    for (var e in list) {
      if (e.amount > 0) {
        spent += e.amount;
      }
    }

    // Category data (excluding Uncategorized)
    final chartData = list
        .where((e) => e.category != "Uncategorized")
        .fold<Map<String, double>>({}, (map, e) {
      map[e.category] = (map[e.category] ?? 0) + e.amount;
      return map;
    });

    final chartSections = chartData.entries
        .map((entry) => _ChartData(entry.key, entry.value))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Expense Tracker"),
        actions: [
          // 🔔 Notifications (Uncategorized)
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
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 24.0, horizontal: 16),
                child: SizedBox(
                  height: 250,
                  child: SfCircularChart(
                    palette: Colors.primaries,
                    legend: Legend(isVisible: false),
                    series: <DoughnutSeries<_ChartData, String>>[
                      DoughnutSeries<_ChartData, String>(
                        dataSource: chartSections,
                        xValueMapper: (_ChartData data, _) => data.category,
                        yValueMapper: (_ChartData data, _) => data.amount,
                        dataLabelSettings: const DataLabelSettings(
                          isVisible: true,
                          labelPosition: ChartDataLabelPosition.outside,
                          textStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        explode: true,
                        explodeGesture: ActivationMode.singleTap,
                        animationDuration: 1200,
                        innerRadius: '70%',
                      ),
                    ],
                    annotations: <CircularChartAnnotation>[
                      CircularChartAnnotation(
                        widget: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Total Spent",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              "₹${spent.toStringAsFixed(2)}",
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // 🔹 Recent Transactions Header Row
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Recent Transactions",
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    child: const Text("See All"),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                            const AllTransactionsScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),

            // 🔹 5 Recent Transactions (excluding Uncategorized)
            ...list
                .where((e) => e.category != "Uncategorized")
                .take(5)
                .map((e) {
              final formattedDate = DateFormat("dd MMM yyyy, hh:mm a")
                  .format(e.dateTime);
              return TransactionCard(e: e, formattedDate: formattedDate);
            }),
          ],
        ),
      ),
    );
  }
}

// 🔹 Chart Data Model
class _ChartData {
  final String category;
  final double amount;

  _ChartData(this.category, this.amount);
}
