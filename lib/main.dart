import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/expense_provider.dart';
import 'screens/home_screen.dart';
import 'screens/uncategorized_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize notification service
  await NotificationService().initNotifications((payload) {
    if (payload == "uncategorized") {
      _navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => const UncategorizedScreen()),
      );
    }
  });

  // ✅ Check if app was launched via a notification
  final details = await NotificationService().getLaunchDetails();
  String? launchPayload = details?.notificationResponse?.payload;

  runApp(
    ChangeNotifierProvider(
      create: (_) => ExpenseProvider(),
      child: MyApp(initialPayload: launchPayload),
    ),
  );
}

// ✅ Global navigator key for notification navigation
final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  final String? initialPayload;
  const MyApp({super.key, this.initialPayload});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Tracker',
      navigatorKey: _navigatorKey,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: _buildInitialScreen(),
    );
  }

  Widget _buildInitialScreen() {
    if (initialPayload == "uncategorized") {
      return const UncategorizedScreen();
    }
    return const HomeScreen();
  }
}
