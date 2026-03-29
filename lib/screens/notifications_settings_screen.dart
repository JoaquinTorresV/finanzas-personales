import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/finance_provider.dart';
import '../theme/app_theme.dart';

class NotificationsSettingsScreen extends StatelessWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pv = context.watch<FinanceProvider>();
    final top = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.fromLTRB(20, top + 16, 20, 100),
        children: [
          Text('Notificaciones', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Configura alertas por condiciones para metas y pagos recurrentes.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          _Card(
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Activar notificaciones'),
              subtitle: const Text('Permite que la app envíe alertas locales.'),
              value: pv.notificationsEnabled,
              onChanged: (value) => pv.setNotificationsEnabled(value),
              activeColor: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          _Card(
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Meta completada'),
                  subtitle: const Text('Avisar cuando una meta alcanza el 100%.'),
                  value: pv.notificationsEnabled &&
                      pv.goalCompletedNotificationsEnabled,
                  onChanged: pv.notificationsEnabled
                      ? (value) => pv.setGoalCompletedNotificationsEnabled(value)
                      : null,
                  activeColor: AppTheme.savings,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Saldo insuficiente para mensualidad'),
                  subtitle: Text(
                    'Avisar si falta saldo para un pago recurrente que vence pronto.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  value: pv.notificationsEnabled &&
                      pv.lowBalanceRecurringNotificationsEnabled,
                  onChanged: pv.notificationsEnabled
                      ? (value) =>
                          pv.setLowBalanceRecurringNotificationsEnabled(value)
                      : null,
                  activeColor: AppTheme.expense,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Anticipación: ${pv.lowBalanceRecurringDaysBefore} días',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                Slider(
                  min: 1,
                  max: 7,
                  divisions: 6,
                  value: pv.lowBalanceRecurringDaysBefore.toDouble(),
                  label: '${pv.lowBalanceRecurringDaysBefore} días',
                  onChanged: pv.notificationsEnabled &&
                          pv.lowBalanceRecurringNotificationsEnabled
                      ? (value) => pv.setLowBalanceRecurringDaysBefore(
                          value.round(),
                        )
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Card(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Las alertas se evalúan al usar la app y se muestran como notificaciones locales en el teléfono.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: child,
    );
  }
}
