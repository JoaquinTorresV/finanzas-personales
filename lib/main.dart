import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'providers/finance_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/main_screen.dart';
import 'services/background_scheduler.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es', null);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final financeProvider = FinanceProvider();
  final themeProvider = ThemeProvider();

  await Future.wait([financeProvider.load(), themeProvider.load()]);
  await initializeBackgroundScheduler();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: financeProvider),
        ChangeNotifierProvider.value(value: themeProvider),
      ],
      child: const FinanzasApp(),
    ),
  );
}

class FinanzasApp extends StatelessWidget {
  const FinanzasApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return MaterialApp(
      title: 'Finanzas',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      home: const _AppRoot(),
    );
  }
}

class _AppRoot extends StatefulWidget {
  const _AppRoot();

  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> with WidgetsBindingObserver {
  FinanceProvider? _financeProvider;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.instance.initialize();
      _triggerNotificationSync();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextProvider = context.read<FinanceProvider>();
    if (_financeProvider == nextProvider) return;

    _financeProvider?.removeListener(_onFinanceChanged);
    _financeProvider = nextProvider;
    _financeProvider?.addListener(_onFinanceChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _financeProvider?.removeListener(_onFinanceChanged);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _triggerNotificationSync();
    }
  }

  void _onFinanceChanged() {
    _triggerNotificationSync();
  }

  Future<void> _triggerNotificationSync() async {
    if (_syncing) return;
    final provider = _financeProvider;
    if (provider == null) return;

    _syncing = true;
    try {
      await NotificationService.instance.processFinanceAlerts(provider);
    } finally {
      _syncing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return const MainScreen();
  }
}
