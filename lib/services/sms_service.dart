import 'package:easy_sms_receiver/easy_sms_receiver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../services/notification_service.dart';

class SmsService {
  final EasySmsReceiver _receiver = EasySmsReceiver.instance;

  /// Start listening to incoming SMS and show ONLY "New Expense" notification.
  Future<void> start(BuildContext context) async {
    final status = await Permission.sms.request();
    if (!status.isGranted) {
      // You might want to surface a snackbar instead of print.
      // But keeping print to avoid UI side-effects here.
      print("❌ SMS permission not granted");
      return;
    }

    _receiver.listenIncomingSms(onNewMessage: (msg) {
      final body = msg.body ?? "";
      final amount = extractAmount(body); // <-- public method

      if (amount != null) {
        NotificationService().showNotification(
          DateTime.now().millisecondsSinceEpoch ~/ 1000, // unique id
          "🆕 New Expense",
          "₹${amount.toStringAsFixed(2)} (Uncategorized)",
          payload: body, // send full SMS body so we can parse on tap
        );
      }
    });
  }

  /// PUBLIC: expose amount parser so other files (e.g., main.dart) can use it.
  double? extractAmount(String text) => _extractAmount(text);

  /// PRIVATE: actual parsing implementation.
  double? _extractAmount(String text) {
    // Matches: INR 1,234.56  | INR123 | INR 450
    final regex = RegExp(r'INR\s?([\d,]+(?:\.\d{1,2})?)', caseSensitive: false);
    final m = regex.firstMatch(text);
    if (m != null) {
      return double.tryParse(m.group(1)!.replaceAll(",", ""));
    }
    return null;
  }

  /// Show categorize popup -> saves to DB after user picks a category.
  void showPopup(BuildContext context, String message) {
    final amount = extractAmount(message) ?? 0.0;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("🆕 New Expense"),
          content: Text("Amount: ₹${amount.toStringAsFixed(2)}\n\nSelect a category"),
          actions: [
            ...["Food", "Transport", "Rent", "Entertainment", "Other"].map((cat) {
              return TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  final exp = Expense(
                    message: message,
                    category: cat,
                    amount: amount,
                    date: DateTime.now(),
                  );
                  Provider.of<ExpenseProvider>(context, listen: false).addExpense(exp);
                },
                child: Text(cat),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  /// Simulate receiving an SMS: shows the same "New Expense" notification.
  void simulateMessage(BuildContext context, String body) {
    final amount = extractAmount(body);
    if (amount == null) {
      // If we can't parse, still notify so user can open and categorize.
      NotificationService().showNotification(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        "🆕 New Expense",
        "Tap to categorize",
        payload: body,
      );
      return;
    }

    NotificationService().showNotification(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      "🆕 New Expense",
      "₹${amount.toStringAsFixed(2)} (Uncategorized)",
      payload: body,
    );
  }
}
