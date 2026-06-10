import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme/app_theme.dart';
import 'screens/dashboard_screen.dart';
import 'screens/sheep_list_screen.dart';
import 'screens/nfc_scan_screen.dart';
import 'screens/economy_screen.dart';
import 'services/database_helper.dart';
import 'services/farm_manager.dart';
import 'services/user_preferences.dart';
import 'screens/onboarding_screen.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarBrightness: Brightness.light,
  ));

  await Supabase.initialize(
    url: 'https://ymbxahznnhxplwjwewxr.supabase.co',
    publishableKey: 'sb_publishable_4nwPecbnCq-2abqqbtuBBg_15hXQZOF',
  );

  await DatabaseHelper.instance.database;
  await UserPreferences.instance.init();
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
      home: const AppRoot(),
    );
  }
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  bool _showSplash = true;
  late bool _onboarded;

  @override
  void initState() {
    super.initState();
    _onboarded = UserPreferences.instance.isOnboardingDone;
  }

  void _onSplashComplete() => setState(() => _showSplash = false);
  void _onOnboardingComplete() => setState(() => _onboarded = true);

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return SplashScreen(onAnimationComplete: _onSplashComplete);
    }
    if (!_onboarded) {
      return OnboardingScreen(onComplete: _onOnboardingComplete);
    }
    return const AppShell();
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

