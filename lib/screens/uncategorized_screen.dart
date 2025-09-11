import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';

class UncategorizedScreen extends StatefulWidget {
  const UncategorizedScreen({super.key});

  @override
  State<UncategorizedScreen> createState() => _UncategorizedScreenState();
}

class _UncategorizedScreenState extends State<UncategorizedScreen> {
  final List<String> categories = const [
    "Food", "Transport", "Rent", "Entertainment", "Other",
  ];

  final expanded = <int, bool>{};

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpenseProvider>(context);
    final uncategorized = provider.uncategorizedExpenses;

    return Scaffold(
      appBar: AppBar(title: const Text("Uncategorized Transactions")),
      body: uncategorized.isEmpty
          ? const Center(child: Text("No uncategorized transactions 🎉"))
          : ListView.builder(
        itemCount: uncategorized.length,
        itemBuilder: (_, index) {
          final e = uncategorized[index];
          final showFull = expanded[e.id ?? index] ?? false;

          return Card(
            margin: const EdgeInsets.all(10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 3,
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              title: Text(
                "₹${e.amount.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.redAccent,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  Text(
                    showFull
                        ? e.title
                        : (e.title.length > 40
                        ? "${e.title.substring(0, 40)}..."
                        : e.title),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  if (e.title.length > 40)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        child: Text(showFull ? "See Less" : "See More"),
                        onPressed: () {
                          setState(() {
                            expanded[e.id ?? index] = !showFull;
                          });
                        },
                      ),
                    ),
                ],
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (cat) {
                  Provider.of<ExpenseProvider>(context, listen: false)
                      .updateExpenseCategory(e.id!, cat);
                },
                itemBuilder: (ctx) {
                  return categories.map((cat) {
                    return PopupMenuItem(value: cat, child: Text(cat));
                  }).toList();
                },
                icon: const Icon(Icons.category, color: Colors.blueAccent),
              ),
            ),
          );
        },
      ),
    );
  }
}
