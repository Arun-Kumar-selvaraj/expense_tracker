import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});
  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  bool showPie = true;
  bool showPercentage = true;

  @override
  Widget build(BuildContext context) {
    final expenses = Provider.of<ExpenseProvider>(context).expenses;

    Map<String, double> categoryData = {};
    for (var e in expenses) {
      categoryData[e.category] =
          (categoryData[e.category] ?? 0) + e.amount;
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Analytics")),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                child: Text(showPie ? "Pie Chart" : "Bar Chart"),
                onPressed: () => setState(() => showPie = !showPie),
              ),
              if (showPie)
                TextButton(
                  child: Text(showPercentage ? "Percentage" : "Amount"),
                  onPressed: () =>
                      setState(() => showPercentage = !showPercentage),
                ),
            ],
          ),
          Expanded(
            child: showPie
                ? PieChartWidget(categoryData, showPercentage)
                : BarChartWidget(categoryData),
          ),
        ],
      ),
    );
  }
}

class PieChartWidget extends StatelessWidget {
  final Map<String, double> data;
  final bool showPercentage;
  const PieChartWidget(this.data, this.showPercentage, {super.key});

  @override
  Widget build(BuildContext context) {
    final total = data.values.fold(0.0, (a, b) => a + b);
    final colors = [Colors.red, Colors.green, Colors.blue, Colors.orange, Colors.purple];

    return Column(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sections: List.generate(data.length, (i) {
                final name = data.keys.elementAt(i);
                final value = data[name]!;
                final percent = ((value / total) * 100).toStringAsFixed(1);
                return PieChartSectionData(
                  color: colors[i % colors.length],
                  value: value,
                  title: showPercentage ? "$percent%" : "₹${value.toStringAsFixed(0)}",
                  radius: 100,
                  titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                );
              }),
              sectionsSpace: 0,
              centerSpaceRadius: 0,
            ),
          ),
        ),
        Wrap(
          spacing: 10,
          children: List.generate(data.length, (i) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 16, height: 16, color: colors[i % colors.length]),
                const SizedBox(width: 4),
                Text(data.keys.elementAt(i)),
              ],
            );
          }),
        ),
      ],
    );
  }
}

class BarChartWidget extends StatelessWidget {
  final Map<String, double> data;
  const BarChartWidget(this.data, {super.key});

  @override
  Widget build(BuildContext context) {
    final colors = [Colors.red, Colors.green, Colors.blue, Colors.orange, Colors.purple];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: BarChart(
        BarChartData(
          maxY: data.values.isNotEmpty ? data.values.reduce((a, b) => a > b ? a : b) * 1.2 : 1,
          barGroups: List.generate(data.length, (i) {
            final name = data.keys.elementAt(i);
            final value = data[name]!;
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: value,
                  color: colors[i % colors.length],
                  width: 20,
                )
              ],
              showingTooltipIndicators: [0],
            );
          }),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < data.length) {
                      return Text(data.keys.elementAt(index));
                    }
                    return const SizedBox();
                  }),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true),
            ),
          ),
        ),
      ),
    );
  }
}
