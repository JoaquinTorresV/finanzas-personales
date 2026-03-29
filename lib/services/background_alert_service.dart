import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/account.dart';
import '../models/recurring_item.dart';
import '../models/savings_goal.dart';
import '../models/transaction.dart';

class BackgroundAlertService {
  static const String _accountsKey = 'accounts';
  static const String _transactionsKey = 'transactions';
  static const String _recurringKey = 'recurring';
  static const String _savingsKey = 'savings';

  static const String _notificationsEnabledKey = 'notificationsEnabled';
  static const String _goalEnabledKey = 'goalCompletedNotificationsEnabled';
  static const String _lowBalanceEnabledKey =
      'lowBalanceRecurringNotificationsEnabled';
  static const String _daysBeforeKey = 'lowBalanceRecurringDaysBefore';

  static const String _sentGoalKeys = 'sentGoalNotificationKeys';
  static const String _sentRecurringKeys = 'sentRecurringNotificationKeys';

  static Future<void> runCheck() async {
    final prefs = await SharedPreferences.getInstance();

    final notificationsEnabled = prefs.getBool(_notificationsEnabledKey) ?? true;
    if (!notificationsEnabled) return;

    final goalEnabled = prefs.getBool(_goalEnabledKey) ?? true;
    final lowBalanceEnabled = prefs.getBool(_lowBalanceEnabledKey) ?? true;
    final daysBefore = (prefs.getInt(_daysBeforeKey) ?? 2).clamp(1, 7);

    final accounts = _decodeList(prefs.getString(_accountsKey), Account.fromJson);
    final transactions =
        _decodeList(prefs.getString(_transactionsKey), Transaction.fromJson);
    final recurringItems =
        _decodeList(prefs.getString(_recurringKey), RecurringItem.fromJson);
    final savingsGoals =
        _decodeList(prefs.getString(_savingsKey), SavingsGoal.fromJson);

    final sentGoal = (prefs.getStringList(_sentGoalKeys) ?? const <String>[]).toSet();
    final sentRecurring =
        (prefs.getStringList(_sentRecurringKeys) ?? const <String>[]).toSet();

    final events = <_BackgroundEvent>[];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (goalEnabled) {
      for (final goal in savingsGoals) {
        if (!goal.isCompleted) continue;
        final key = 'goal_completed_${goal.id}';
        if (sentGoal.contains(key)) continue;

        final accountName = _accountName(accounts, goal.accountId);
        events.add(_BackgroundEvent(
          key: key,
          title: 'Meta completada',
          body: '${goal.icon} ${goal.name} completada en $accountName.',
        ));
        sentGoal.add(key);
      }
    }

    if (lowBalanceEnabled) {
      for (final account in accounts) {
        final monthBalance = _accountBalanceForMonth(
          transactions: transactions,
          accountId: account.id,
          year: today.year,
          month: today.month,
        );

        final items = recurringItems.where(
          (r) => r.accountId == account.id && r.isExpense && r.isActive,
        );

        for (final item in items) {
          var dueDate = DateTime(today.year, today.month, item.dayOfMonth.clamp(1, 28));
          if (dueDate.isBefore(today)) {
            dueDate = DateTime(today.year, today.month + 1, item.dayOfMonth.clamp(1, 28));
          }

          final daysUntil = dueDate.difference(today).inDays;
          final inWindow = daysUntil >= 0 && daysUntil <= daysBefore;
          final lowBalance = monthBalance < item.amount;
          if (!inWindow || !lowBalance) continue;

          final key = 'rec_low_${item.id}_${dueDate.year}_${dueDate.month}';
          if (sentRecurring.contains(key)) continue;

          events.add(_BackgroundEvent(
            key: key,
            title: 'Saldo insuficiente',
            body: 'En ${account.name} faltan fondos para ${item.description} (vence en $daysUntil d).',
          ));
          sentRecurring.add(key);
        }
      }
    }

    if (events.isEmpty) return;

    await _showNotifications(events);
    await prefs.setStringList(_sentGoalKeys, sentGoal.toList());
    await prefs.setStringList(_sentRecurringKeys, sentRecurring.toList());
  }

  static List<T> _decodeList<T>(
    String? raw,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (raw == null || raw.isEmpty) return <T>[];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static String _accountName(List<Account> accounts, String accountId) {
    for (final account in accounts) {
      if (account.id == accountId) return account.name;
    }
    return 'tu cuenta';
  }

  static double _accountBalanceForMonth({
    required List<Transaction> transactions,
    required String accountId,
    required int year,
    required int month,
  }) {
    final txs = transactions.where((t) =>
        t.accountId == accountId && t.date.year == year && t.date.month == month);

    return txs.fold(0.0, (sum, tx) => sum + (tx.isIncome ? tx.amount : -tx.amount));
  }

  static Future<void> _showNotifications(List<_BackgroundEvent> events) async {
    final plugin = FlutterLocalNotificationsPlugin();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await plugin.initialize(settings);

    const androidDetails = AndroidNotificationDetails(
      'finanzas_alertas_bg',
      'Alertas en segundo plano',
      channelDescription: 'Alertas financieras en segundo plano',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    for (final event in events) {
      await plugin.show(
        event.key.hashCode & 0x7fffffff,
        event.title,
        event.body,
        details,
      );
    }
  }
}

class _BackgroundEvent {
  final String key;
  final String title;
  final String body;

  const _BackgroundEvent({
    required this.key,
    required this.title,
    required this.body,
  });
}
