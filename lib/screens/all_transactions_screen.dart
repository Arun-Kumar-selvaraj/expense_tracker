import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/expense_provider.dart';
import '../widgets/transaction_card.dart';

class AllTransactionsScreen extends StatelessWidget {
  const AllTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpenseProvider>(context);
    final list = provider.expenses;

    return Scaffold(
      appBar: AppBar(title: const Text("All Transactions")),
      body: list.isEmpty
          ? const Center(child: Text("No transactions found"))
          : ListView.builder(
        itemCount: list.length,
        itemBuilder: (_, i) {
          final e = list[i];
          final formattedDate =
          DateFormat("dd MMM yyyy, hh:mm a").format(e.dateTime);
          return TransactionCard(e: e, formattedDate: formattedDate);
        },
      ),
    );
  }
}
