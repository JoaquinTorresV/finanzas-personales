import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'transactions_screen.dart';
import 'recurring_screen.dart';
import 'savings_screen.dart';
import 'analytics_screen.dart';
import 'calendar_screen.dart';
import '../theme/app_theme.dart';
import '../providers/theme_provider.dart';
import 'package:provider/provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;

  static const _screens = [
    HomeScreen(),
    TransactionsScreen(),
    CalendarScreen(),
    RecurringScreen(),
    SavingsScreen(),
    AnalyticsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final surf = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final bord = isDark ? AppTheme.darkBorder  : AppTheme.lightBorder;

    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: surf,
          border: Border(top: BorderSide(color: bord)),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Inicio',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long_rounded),
              label: 'Movimientos',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month_rounded),
              label: 'Calendario',
            ),
            NavigationDestination(
              icon: Icon(Icons.repeat_rounded),
              selectedIcon: Icon(Icons.repeat_rounded),
              label: 'Fijos',
            ),
            NavigationDestination(
              icon: Icon(Icons.savings_outlined),
              selectedIcon: Icon(Icons.savings_rounded),
              label: 'Ahorros',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart_rounded),
              label: 'Análisis',
            ),
          ],
        ),
      ),
    );
  }
}
