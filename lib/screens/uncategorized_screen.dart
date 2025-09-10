import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';

class UncategorizedScreen extends StatelessWidget {
  const UncategorizedScreen({super.key});

  final List<String> categories = const [
    "Food",
    "Transport",
    "Rent",
    "Entertainment",
    "Other",
  ];

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
          return Card(
            margin: const EdgeInsets.all(10),
            child: ListTile(
              title: Text("₹${e.amount.toStringAsFixed(2)}"),
              subtitle: Text(e.title),
              trailing: ElevatedButton(
                child: const Text("Choose Category"),
                onPressed: () => _showCategoryPicker(context, e.id!),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showCategoryPicker(BuildContext context, int expenseId) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return ListView(
          shrinkWrap: true,
          children: categories.map((cat) {
            return ListTile(
              leading: const Icon(Icons.category),
              title: Text(cat),
              onTap: () async {
                await Provider.of<ExpenseProvider>(context, listen: false)
                    .updateExpenseCategory(expenseId, cat);
                Navigator.pop(context);
              },
            );
          }).toList(),
        );
      },
    );
  }
}
