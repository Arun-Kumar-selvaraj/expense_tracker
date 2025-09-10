import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../models/expense.dart';

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
          return Dismissible(
            key: Key(e.id.toString()),
            direction: DismissDirection.endToStart,
            confirmDismiss: (_) => _confirmDelete(context, e.id!),
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            child: Card(
              margin: const EdgeInsets.all(10),
              child: ListTile(
                title: Text("₹${e.amount.toStringAsFixed(2)}"),
                subtitle: Text(e.title),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      child: const Text("Category"),
                      onPressed: () => _showCategoryPicker(context, e.id!),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmDelete(context, e.id!),
                    ),
                  ],
                ),
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

  Future<bool> _confirmDelete(BuildContext context, int expenseId) async {
    return await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Delete Transaction"),
          content: const Text(
              "Are you sure you want to delete this transaction?"),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.of(ctx).pop(false),
            ),
            TextButton(
              child:
              const Text("Delete", style: TextStyle(color: Colors.red)),
              onPressed: () async {
                await Provider.of<ExpenseProvider>(context, listen: false)
                    .deleteExpense(expenseId);
                Navigator.of(ctx).pop(true);
              },
            ),
          ],
        );
      },
    ) ??
        false;
  }
}
