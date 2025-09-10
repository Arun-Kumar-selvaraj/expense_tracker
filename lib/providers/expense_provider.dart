import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../db/expense_db.dart';

class ExpenseProvider with ChangeNotifier {
  List<Expense> _expenses = [];

  List<Expense> get expenses => _expenses;

  Future<void> fetchExpenses() async {
    final data = await DatabaseHelper.instance.getExpenses();
    _expenses = data.map((e) => Expense.fromMap(e)).toList();
    notifyListeners();
  }

  Future<void> addExpense(Expense expense) async {
    await DatabaseHelper.instance.insertExpense(expense);
    await fetchExpenses();
  }

  Future<void> updateExpenseCategory(int id, String category) async {
    await DatabaseHelper.instance.updateExpenseCategory(id, category);
    await fetchExpenses();
  }

  List<Expense> get uncategorizedExpenses =>
      _expenses.where((e) => e.category == "Uncategorized").toList();
}
