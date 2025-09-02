import 'package:flutter/material.dart';
import '../db/expense_db.dart';
import '../models/expense.dart';

class ExpenseProvider with ChangeNotifier {
  List<Expense> _list = [];
  List<Expense> get expenses => _list;

  Future<void> load() async {
    final data = await DatabaseHelper().getExpenses();
    _list = data.map((e) => Expense.fromMap(e)).toList();
    notifyListeners();
  }

  Future<void> addExpense(Expense e) async {
    await DatabaseHelper().insertExpense(e.toMap());
    await load();
  }
}
