import 'package:easy_sms_receiver/easy_sms_receiver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../services/notification_service.dart';

class SmsService {
  final EasySmsReceiver _receiver = EasySmsReceiver.instance;

  Future<void> start(BuildContext context) async {
    var status = await Permission.sms.request();
    if (!status.isGranted) return;

    _receiver.listenIncomingSms(
      onNewMessage: (msg) async {
        final body = msg.body ?? "";

        // ✅ Only process if SMS looks like a bank transaction
        if (!_isBankMessage(body)) return;

        final amount = _extractAmount(body);
        if (amount == null) return;

        // ✅ Save expense immediately as Uncategorized
        final exp = Expense(
          title: body,
          amount: amount,
          dateTime: DateTime.now(),
          category: "Uncategorized",
        );
        await Provider.of<ExpenseProvider>(context, listen: false)
            .addExpense(exp);

        // ✅ Show notification using NotificationService
        await NotificationService().showNotification(
          DateTime.now().millisecondsSinceEpoch ~/ 1000, // unique ID
          "💸 ${_getTransactionType(body)}",
          "₹${amount.toStringAsFixed(2)} - Tap to categorize",
          payload: "uncategorized",
        );
      },
    );
  }

  /// Extract amount from SMS text
  double? _extractAmount(String text) {
    final regex =
    RegExp(r'INR\s?([\d,]+(?:\.\d{1,2})?)', caseSensitive: false);
    final m = regex.firstMatch(text);
    if (m != null) {
      return double.tryParse(m.group(1)!.replaceAll(",", ""));
    }
    return null;
  }

  /// Detect if SMS is a bank-related transaction
  bool _isBankMessage(String text) {
    final lower = text.toLowerCase();
    return lower.contains("debited") ||
        lower.contains("credited") ||
        lower.contains("txn") ||
        lower.contains("a/c") ||
        lower.contains("account");
  }

  /// Determine transaction type for notification title
  String _getTransactionType(String text) {
    final lower = text.toLowerCase();
    if (lower.contains("debited")) return "Debited";
    if (lower.contains("credited")) return "Credited";
    return "Transaction";
  }

  /// Simulate SMS for testing without real SMS
  void simulateMessage(BuildContext context, String body) async {
    if (!_isBankMessage(body)) return;

    final amount = _extractAmount(body);
    if (amount == null) return;

    final exp = Expense(
      title: body,
      amount: amount,
      dateTime: DateTime.now(),
      category: "Uncategorized",
    );
    await Provider.of<ExpenseProvider>(context, listen: false)
        .addExpense(exp);

    await NotificationService().showNotification(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      "💸 ${_getTransactionType(body)}",
      "₹${amount.toStringAsFixed(2)} - Tap to categorize",
      payload: "uncategorized",
    );
  }
}
