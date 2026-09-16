import 'package:hive_flutter/hive_flutter.dart';

import '../../models/task.dart';
import '../sync/pending_operation.dart';

/// Box names and one-time Hive initialization / adapter registration.
class HiveBoxes {
  static const tasksCache = 'tasks_cache';
  static const pendingOps = 'pending_ops';
  static const prefs = 'app_prefs';

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter();
    Hive.registerAdapter(TaskAdapter());
    Hive.registerAdapter(TaskStatusAdapter());
    Hive.registerAdapter(PendingOperationAdapter());
    Hive.registerAdapter(PendingOpTypeAdapter());

    await Hive.openBox<Task>(tasksCache);
    await Hive.openBox<PendingOperation>(pendingOps);
    await Hive.openBox(prefs);
    _initialized = true;
  }

  static Box<Task> get tasksBox => Hive.box<Task>(tasksCache);

  static Box<PendingOperation> get pendingOpsBox =>
      Hive.box<PendingOperation>(pendingOps);

  static Box get prefsBox => Hive.box(prefs);
}
