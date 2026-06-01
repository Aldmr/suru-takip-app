import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'theme/app_theme.dart';
import 'screens/dashboard_screen.dart';
import 'screens/sheep_list_screen.dart';
import 'screens/nfc_scan_screen.dart';
import 'screens/economy_screen.dart';
import 'services/database_helper.dart';
import 'services/farm_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarBrightness: Brightness.light,
  ));

  // Initialize DB and seed demo data if needed
  await DatabaseHelper.instance.database;
  await DatabaseHelper.instance.ensureDemoData();
  await FarmManager.instance.init();

  runApp(const SuruTakipApp());
}

class SuruTakipApp extends StatelessWidget {
  const SuruTakipApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SürüTakip',
      theme: AppTheme.theme,
      debugShowCheckedModeBanner: false,
      locale: const Locale('tr', 'TR'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('tr', 'TR')],
      home: const AppShell(),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _navIndex = 0;
  int _dashboardKey = 0;

  void _onNavTap(int index) {
    setState(() {
      if (index == 0) _dashboardKey++;
      _navIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return switch (_navIndex) {
      0 => DashboardScreen(key: ValueKey(_dashboardKey), navIndex: _navIndex, onNavTap: _onNavTap),
      1 => SheepListScreen(navIndex: _navIndex, onNavTap: _onNavTap),
      2 => NfcScanScreen(navIndex: _navIndex, onNavTap: _onNavTap),
      _ => EconomyScreen(navIndex: _navIndex, onNavTap: _onNavTap),
    };
  }
}

