import 'package:hive/hive.dart';

import '../../models/task.dart';
import '../storage/hive_boxes.dart';

/// Local cache of the last-known task list, keyed by [Task.cacheKey], so the
/// list screen always has something to show even fully offline.
class TaskCache {
  Box<Task> get _box => HiveBoxes.tasksBox;

  List<Task> get all =>
      _box.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  Task? get(String cacheKey) => _box.get(cacheKey);

  Future<void> put(Task task) => _box.put(task.cacheKey, task);

  Future<void> delete(String cacheKey) => _box.delete(cacheKey);

  Stream<void> watch() => _box.watch().map((_) {});

  /// Replaces the cache with a fresh server response, but keeps any
  /// locally-created tasks that haven't synced yet (they have no place in
  /// a server response since the server doesn't know about them).
  Future<void> replaceFromServer(List<Task> serverTasks) async {
    final unsynced = _box.values.where((t) => !t.isSynced).toList();
    await _box.clear();
    for (final task in serverTasks) {
      await _box.put(task.cacheKey, task);
    }
    for (final task in unsynced) {
      await _box.put(task.cacheKey, task);
    }
  }

  /// Moves a task from its temporary local key to its server-assigned key,
  /// once a queued create has synced.
  Future<void> reconcileId(String oldKey, Task synced) async {
    await _box.delete(oldKey);
    await _box.put(synced.cacheKey, synced);
  }
}
