import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/expense_provider.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});
  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  bool showPercentage = true;

  @override
  Widget build(BuildContext context) {
    final expenses = Provider.of<ExpenseProvider>(context).expenses;
    // aggregate by category
    final Map<String, double> data = {};
    for (final e in expenses) {
      data[e.category] = (data[e.category] ?? 0) + e.amount;
    }

    final total = data.values.fold(0.0, (a, b) => a + b);

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // toggles
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => setState(() => showPercentage = true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: showPercentage ? Theme.of(context).primaryColor : Colors.grey.shade200,
                  ),
                  child: Text('Percentage', style: TextStyle(color: showPercentage ? Colors.white : Colors.black)),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => setState(() => showPercentage = false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: !showPercentage ? Theme.of(context).primaryColor : Colors.grey.shade200,
                  ),
                  child: Text('Amount', style: TextStyle(color: !showPercentage ? Colors.white : Colors.black)),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Donut
            Expanded(
              child: data.isEmpty
                  ? const Center(child: Text('No data for chart'))
                  : Column(
                children: [
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        sections: _buildSections(data, total, showPercentage),
                        centerSpaceRadius: 60,
                        sectionsSpace: 4,
                        pieTouchData: PieTouchData(
                          touchCallback: (p, d) {},
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: List.generate(data.length, (i) {
                      final name = data.keys.elementAt(i);
                      final value = data[name]!;
                      return _LegendItem(name: name, value: value, index: i);
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildSections(Map<String, double> data, double total, bool showPercentage) {
    final colors = [Colors.red, Colors.green, Colors.blue, Colors.orange, Colors.purple, Colors.teal];
    final entries = data.entries.toList();
    return List.generate(entries.length, (i) {
      final name = entries[i].key;
      final value = entries[i].value;
      final percent = total > 0 ? (value / total * 100) : 0.0;
      final title = showPercentage ? '${percent.toStringAsFixed(1)}%' : '₹${value.toStringAsFixed(0)}';
      return PieChartSectionData(
        value: value,
        title: title,
        radius: 90,
        color: colors[i % colors.length],
        titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
      );
    });
  }
}

class _LegendItem extends StatelessWidget {
  final String name;
  final double value;
  final int index;
  const _LegendItem({required this.name, required this.value, required this.index});

  @override
  Widget build(BuildContext context) {
    final colors = [Colors.red, Colors.green, Colors.blue, Colors.orange, Colors.purple, Colors.teal];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, color: colors[index % colors.length]),
        const SizedBox(width: 6),
        Text('$name — ₹${value.toStringAsFixed(0)}'),
      ],
    );
  }
}
