import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import 'background_alert_service.dart';

const String financeBackgroundTask = 'finance_background_alerts_task';

@pragma('vm:entry-point')
void financeBackgroundDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName == financeBackgroundTask) {
      await BackgroundAlertService.runCheck();
    }
    return true;
  });
}

Future<void> initializeBackgroundScheduler() async {
  await Workmanager().initialize(
    financeBackgroundDispatcher,
    isInDebugMode: kDebugMode,
  );

  await Workmanager().registerPeriodicTask(
    'finance_background_alerts_unique',
    financeBackgroundTask,
    frequency: const Duration(hours: 1),
    initialDelay: const Duration(minutes: 15),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
    constraints: Constraints(networkType: NetworkType.notRequired),
  );
}
