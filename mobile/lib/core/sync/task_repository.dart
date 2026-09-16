import 'package:uuid/uuid.dart';

import '../../models/task.dart';
import '../api/task_api.dart';
import 'connectivity_service.dart';
import 'pending_ops_queue.dart';
import 'sync_service.dart';
import 'task_cache.dart';

const _uuid = Uuid();

/// The single entry point every screen goes through to read or mutate
/// tasks. It transparently decides "online -> call the API directly" vs
/// "offline -> write to the local cache and enqueue a pending operation",
/// so screens never need to know which mode they're in.
class TaskRepository {
  TaskRepository({
    required TaskApi taskApi,
    required ConnectivityService connectivity,
    required TaskCache cache,
    required PendingOpsQueue queue,
    required SyncService syncService,
  }) : _taskApi = taskApi,
       _connectivity = connectivity,
       _cache = cache,
       _queue = queue,
       _syncService = syncService;

  final TaskApi _taskApi;
  final ConnectivityService _connectivity;
  final TaskCache _cache;
  final PendingOpsQueue _queue;
  final SyncService _syncService;

  bool get isOnline => _connectivity.isOnline;

  /// Cached tasks, filtered/searched locally the same way the server would.
  List<Task> readCached({TaskStatus? status, String? search}) {
    var tasks = _cache.all;
    if (status != null) {
      tasks = tasks.where((t) => t.status == status).toList();
    }
    if (search != null && search.trim().isNotEmpty) {
      final q = search.trim().toLowerCase();
      tasks = tasks
          .where(
            (t) =>
                t.title.toLowerCase().contains(q) ||
                t.description.toLowerCase().contains(q),
          )
          .toList();
    }
    return tasks;
  }

  /// Fetches the list, hitting the API when online (and refreshing the
  /// cache), or falling back to the cache when offline.
  Future<List<Task>> fetchTasks({TaskStatus? status, String? search}) async {
    if (_connectivity.isOnline) {
      try {
        final tasks = await _taskApi.list(status: status, search: search);
        // Only overwrite the full cache on an unfiltered fetch; a filtered
        // fetch's results aren't the complete picture.
        if (status == null && (search == null || search.isEmpty)) {
          await _cache.replaceFromServer(tasks);
        }
        return tasks;
      } catch (_) {
        return readCached(status: status, search: search);
      }
    }
    return readCached(status: status, search: search);
  }

  Future<Task> createTask({
    required String title,
    required String description,
    required TaskStatus status,
  }) async {
    if (_connectivity.isOnline) {
      final created = await _taskApi.create(
        title: title,
        description: description,
        status: status,
      );
      await _cache.put(created);
      return created;
    }
    final now = DateTime.now();
    final local = Task(
      localId: _uuid.v4(),
      id: null,
      title: title,
      description: description,
      status: status,
      createdAt: now,
      updatedAt: now,
    );
    await _cache.put(local);
    await _queue.enqueueCreate(local.cacheKey, local.toRequestJson());
    return local;
  }

  Future<Task> updateTask(
    Task task, {
    required String title,
    required String description,
    required TaskStatus status,
  }) async {
    final updatedLocal = task.copyWith(
      title: title,
      description: description,
      status: status,
      updatedAt: DateTime.now(),
    );
    if (_connectivity.isOnline && task.isSynced) {
      final updated = await _taskApi.update(
        task.id!,
        title: title,
        description: description,
        status: status,
      );
      await _cache.put(updated);
      return updated;
    }
    // Offline (or online but not yet synced, e.g. mid-drain): write local
    // and enqueue/coalesce.
    await _cache.put(updatedLocal);
    await _queue.enqueueUpdate(
      updatedLocal.cacheKey,
      updatedLocal.toRequestJson(),
    );
    return updatedLocal;
  }

  Future<void> deleteTask(Task task) async {
    if (_connectivity.isOnline && task.isSynced) {
      await _taskApi.delete(task.id!);
      await _cache.delete(task.cacheKey);
      return;
    }
    // Whether or not the create was cancelled outright, the task should no
    // longer show up locally.
    await _queue.enqueueDelete(task.cacheKey);
    await _cache.delete(task.cacheKey);
  }

  int get pendingCount => _queue.pendingCount;

  Future<void> sync() => _syncService.drain().then((_) {});
}
