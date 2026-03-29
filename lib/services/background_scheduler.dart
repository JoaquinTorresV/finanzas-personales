import 'background_scheduler_stub.dart'
    if (dart.library.io) 'background_scheduler_io.dart' as scheduler_impl;

Future<void> initializeBackgroundScheduler() {
  return scheduler_impl.initializeBackgroundScheduler();
}
