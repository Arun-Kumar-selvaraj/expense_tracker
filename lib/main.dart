import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/expense_provider.dart';
import 'services/notification_service.dart';
import 'services/sms_service.dart';
import 'screens/home_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final SmsService smsService = SmsService(); // reuse the same instance

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notifications with tap callback:
  await NotificationService().initNotifications((payload) {
    final ctx = navigatorKey.currentContext;
    if (ctx != null) {
      // On tap -> open categorize popup
      smsService.showPopup(ctx, payload);
    }
  });

  runApp(
    ChangeNotifierProvider(
      create: (_) => ExpenseProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // needed to show popup from tap callback
      title: 'Expense Tracker',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomeScreen(),
    );
  }
}
