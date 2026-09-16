import 'dart:io';

import 'package:hive/hive.dart';
import 'package:task_manager/core/storage/hive_boxes.dart';
import 'package:task_manager/core/sync/pending_operation.dart';
import 'package:task_manager/models/task.dart';

/// Initializes Hive against a throwaway temp directory (instead of a real
/// device path via hive_flutter's platform channel, which isn't available
/// in plain `flutter test`), and opens the same boxes the app uses.
class HiveTestHelper {
  static Directory? _tempDir;
  static bool _adaptersRegistered = false;

  static Future<void> setUp() async {
    _tempDir = await Directory.systemTemp.createTemp('task_manager_hive_test_');
    Hive.init(_tempDir!.path);
    if (!_adaptersRegistered) {
      Hive.registerAdapter(TaskAdapter());
      Hive.registerAdapter(TaskStatusAdapter());
      Hive.registerAdapter(PendingOperationAdapter());
      Hive.registerAdapter(PendingOpTypeAdapter());
      _adaptersRegistered = true;
    }
    await Hive.openBox<Task>(HiveBoxes.tasksCache);
    await Hive.openBox<PendingOperation>(HiveBoxes.pendingOps);
    await Hive.openBox(HiveBoxes.prefs);
  }

  static Future<void> tearDown() async {
    await Hive.deleteFromDisk();
    if (_tempDir != null && _tempDir!.existsSync()) {
      _tempDir!.deleteSync(recursive: true);
    }
  }
}
