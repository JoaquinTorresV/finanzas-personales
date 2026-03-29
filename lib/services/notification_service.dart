import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../providers/finance_provider.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings);

    final android =
        _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();

    final ios =
        _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);

    _initialized = true;
  }

  Future<void> processFinanceAlerts(FinanceProvider provider) async {
    if (kIsWeb) return;
    if (!_initialized) await initialize();

    final events = await provider.collectNotificationEvents();
    for (final event in events) {
      await _showEvent(event);
    }
  }

  Future<void> _showEvent(FinanceNotificationEvent event) async {
    const androidDetails = AndroidNotificationDetails(
      'finanzas_alertas',
      'Alertas de finanzas',
      channelDescription: 'Alertas de metas y pagos recurrentes',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );
    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      event.key.hashCode & 0x7fffffff,
      event.title,
      event.body,
      details,
    );
  }
}
