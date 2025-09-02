import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pie_chart/pie_chart.dart' as pc; // alias for pie_chart
import 'package:fl_chart/fl_chart.dart' as fl; // alias for fl_chart

import '../providers/expense_provider.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  bool showPercentage = true;
  bool showPieChart = true;

  final Map<String, Color> categoryColors = {
    "Food": Colors.red,
    "Transport": Colors.green,
    "Rent": Colors.blue,
    "Entertainment": Colors.orange,
    "Other": Colors.purple,
  };

  @override
  Widget build(BuildContext context) {
    final expenses = Provider.of<ExpenseProvider>(context).expenses;

    final Map<String, double> dataMap = {};
    for (var e in expenses) {
      dataMap[e.category] = (dataMap[e.category] ?? 0) + e.amount;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Analytics"),
        actions: [
          IconButton(
            icon: Icon(showPieChart ? Icons.bar_chart : Icons.pie_chart),
            tooltip: showPieChart ? "Switch to Bar Chart" : "Switch to Pie Chart",
            onPressed: () => setState(() => showPieChart = !showPieChart),
          ),
          if (showPieChart)
            IconButton(
              icon: Icon(showPercentage ? Icons.percent : Icons.currency_rupee),
              tooltip: showPercentage ? "Show Amounts" : "Show Percentage",
              onPressed: () => setState(() => showPercentage = !showPercentage),
            ),
        ],
      ),
      body: expenses.isEmpty
          ? const Center(child: Text("No data yet"))
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: showPieChart
            ? _buildPieChart(dataMap)
            : _buildBarChart(dataMap),
      ),
    );
  }

  /// Pie Chart using `pie_chart` package
  Widget _buildPieChart(Map<String, double> dataMap) {
    return Column(
      children: [
        Expanded(
          child: pc.PieChart(
            dataMap: dataMap,
            animationDuration: const Duration(milliseconds: 800),
            chartType: pc.ChartType.disc,
            chartLegendSpacing: 40,
            chartValuesOptions: pc.ChartValuesOptions(
              showChartValuesInPercentage: showPercentage,
              showChartValues: true,
              showChartValuesOutside: false,
              decimalPlaces: 1,
            ),
            colorList: dataMap.keys
                .map((cat) => categoryColors[cat] ?? Colors.grey)
                .toList(),
            legendOptions: const pc.LegendOptions(
              showLegends: false, // hide built-in legend
            ),
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: dataMap.keys.map((cat) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 14,
                  height: 14,
                  color: categoryColors[cat] ?? Colors.grey,
                ),
                const SizedBox(width: 6),
                Text(cat, style: const TextStyle(fontSize: 14)),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Bar Chart using `fl_chart` package
  Widget _buildBarChart(Map<String, double> dataMap) {
    final categories = dataMap.keys.toList();
    final amounts = dataMap.values.toList();

    return fl.BarChart(
      fl.BarChartData(
        alignment: fl.BarChartAlignment.spaceAround,
        barTouchData: fl.BarTouchData(enabled: true),
        titlesData: fl.FlTitlesData(
          leftTitles: fl.AxisTitles(
            sideTitles: fl.SideTitles(showTitles: true, reservedSize: 40),
          ),
          rightTitles: fl.AxisTitles(sideTitles: fl.SideTitles(showTitles: false)),
          topTitles: fl.AxisTitles(sideTitles: fl.SideTitles(showTitles: false)),
          bottomTitles: fl.AxisTitles(
            sideTitles: fl.SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= categories.length) {
                  return const SizedBox.shrink();
                }
                return Text(categories[index],
                    style: const TextStyle(fontSize: 12));
              },
            ),
          ),
        ),
        borderData: fl.FlBorderData(show: false),
        barGroups: List.generate(categories.length, (index) {
          return fl.BarChartGroupData(
            x: index,
            barRods: [
              fl.BarChartRodData(
                toY: amounts[index],
                color: categoryColors[categories[index]] ?? Colors.grey,
                width: 22,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }),
      ),
    );
  }
}
