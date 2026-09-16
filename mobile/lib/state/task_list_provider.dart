import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/api/api_exception.dart';
import '../core/sync/connectivity_service.dart';
import '../core/sync/pending_ops_queue.dart';
import '../core/sync/task_repository.dart';
import '../models/task.dart';

enum ListLoadState { initial, loading, loaded, error }

/// Drives the TaskListScreen: current filter/search, the task list itself,
/// and live online/offline + pending-op-count state so the status pill can
/// update in real time.
class TaskListProvider extends ChangeNotifier {
  TaskListProvider({
    required TaskRepository repository,
    required ConnectivityService connectivity,
    required PendingOpsQueue pendingOpsQueue,
  }) : _repository = repository,
       _connectivity = connectivity,
       _pendingOpsQueue = pendingOpsQueue {
    _connectivitySub = _connectivity.onStatusChange.listen(
      _onConnectivityChanged,
    );
    _pendingOpsSub = _pendingOpsQueue.watch().listen((_) => notifyListeners());
  }

  final TaskRepository _repository;
  final ConnectivityService _connectivity;
  final PendingOpsQueue _pendingOpsQueue;
  late final StreamSubscription<bool> _connectivitySub;
  late final StreamSubscription<void> _pendingOpsSub;

  ListLoadState loadState = ListLoadState.initial;
  List<Task> tasks = [];
  TaskStatus? filterStatus;
  String search = '';
  String? errorMessage;

  bool get isOnline => _connectivity.isOnline;
  int get pendingCount => _pendingOpsQueue.pendingCount;

  Future<void> init() async {
    await _connectivity.refresh();
    await load();
    if (isOnline) unawaited(_syncThenReload());
  }

  Future<void> _onConnectivityChanged(bool online) async {
    notifyListeners();
    if (online) {
      await _syncThenReload();
    }
  }

  Future<void> _syncThenReload() async {
    await _repository.sync();
    await load(silent: true);
  }

  Future<void> load({bool silent = false}) async {
    if (!silent) loadState = ListLoadState.loading;
    errorMessage = null;
    notifyListeners();
    try {
      tasks = await _repository.fetchTasks(
        status: filterStatus,
        search: search,
      );
      loadState = ListLoadState.loaded;
    } on ApiException catch (e) {
      errorMessage = e.message;
      tasks = _repository.readCached(status: filterStatus, search: search);
      loadState = ListLoadState.loaded;
    } catch (_) {
      errorMessage = 'Impossible de charger les tâches.';
      tasks = _repository.readCached(status: filterStatus, search: search);
      loadState = ListLoadState.loaded;
    }
    notifyListeners();
  }

  void setFilter(TaskStatus? status) {
    filterStatus = status;
    load();
  }

  void setSearch(String value) {
    search = value;
    load();
  }

  Future<Task> createTask({
    required String title,
    required String description,
    required TaskStatus status,
  }) async {
    final task = await _repository.createTask(
      title: title,
      description: description,
      status: status,
    );
    await load(silent: true);
    return task;
  }

  Future<void> updateTask(
    Task task, {
    required String title,
    required String description,
    required TaskStatus status,
  }) async {
    await _repository.updateTask(
      task,
      title: title,
      description: description,
      status: status,
    );
    await load(silent: true);
  }

  Future<void> deleteTask(Task task) async {
    await _repository.deleteTask(task);
    await load(silent: true);
  }

  @override
  void dispose() {
    _connectivitySub.cancel();
    _pendingOpsSub.cancel();
    super.dispose();
  }
}
