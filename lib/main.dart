import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quick_actions/quick_actions.dart';
import 'services/storage_service.dart';
import 'theme.dart';
import 'screens/home_screen.dart';
import 'screens/add_transaction_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const SpendSnapApp());
}

class SpendSnapApp extends StatefulWidget {
  const SpendSnapApp({super.key});
  @override
  State<SpendSnapApp> createState() => _SpendSnapAppState();
}

class _SpendSnapAppState extends State<SpendSnapApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _setupQuickActions();
  }

  void _setupQuickActions() {
    const quickActions = QuickActions();
    quickActions.setShortcutItems([
      const ShortcutItem(
        type: 'add_expense',
        localizedTitle: 'Add Expense',
        icon: 'ic_add',
      ),
    ]);
    quickActions.initialize((type) {
      if (type == 'add_expense') {
        _navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SpendSnap',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      navigatorKey: _navigatorKey,
      home: const HomeScreen(),
    );
  }
}
