import 'dart:async';

import '../../models/task.dart';
import '../api/api_client.dart';
import '../api/task_api.dart';
import 'pending_operation.dart';
import 'pending_ops_queue.dart';
import 'task_cache.dart';

/// Drains the pending-operations queue against the real API, in order,
/// once connectivity returns. Reconciles client-generated ids with
/// server ids and keeps the local cache in sync.
///
/// Operations are processed strictly in insertion order and one at a time:
/// if one fails on a network error, draining stops there (so ordering is
/// preserved) and the same operation is retried on the next sync pass,
/// rather than being dropped. A definitive server rejection (e.g. 404 for
/// an update/delete of a task that no longer exists) is treated as
/// resolved and the op is discarded so it doesn't retry forever.
class SyncService {
  SyncService({
    required TaskApi taskApi,
    required PendingOpsQueue queue,
    required TaskCache cache,
  })  : _taskApi = taskApi,
        _queue = queue,
        _cache = cache;

  final TaskApi _taskApi;
  final PendingOpsQueue _queue;
  final TaskCache _cache;

  bool _syncing = false;
  final _resultController = StreamController<SyncResult>.broadcast();
  Stream<SyncResult> get onSyncResult => _resultController.stream;

  bool get isSyncing => _syncing;

  Future<SyncResult> drain() async {
    if (_syncing) return SyncResult.alreadyRunning;
    _syncing = true;
    try {
      for (final op in _queue.all) {
        final ok = await _processOne(op);
        if (!ok) {
          final result = SyncResult.partialFailure;
          _resultController.add(result);
          return result;
        }
      }
      final result = SyncResult.success;
      _resultController.add(result);
      return result;
    } finally {
      _syncing = false;
    }
  }

  /// Returns true if this op was resolved (synced or definitively
  /// dropped) and draining should continue; false if it should stop here
  /// and be retried later.
  Future<bool> _processOne(PendingOperation op) async {
    try {
      switch (op.type) {
        case PendingOpType.create:
          final created = await _taskApi.create(
            title: op.payload['title'] as String,
            description: op.payload['description'] as String,
            status: TaskStatusWire.fromWire(op.payload['status'] as String),
          );
          await _cache.reconcileId(op.taskKey, created);
          await _queue.remove(op.opId);
          return true;
        case PendingOpType.update:
          final id = int.tryParse(op.taskKey);
          if (id == null) {
            // Shouldn't happen: an update can only be queued for a task
            // that already has a server id. Drop defensively.
            await _queue.remove(op.opId);
            return true;
          }
          final updated = await _taskApi.update(
            id,
            title: op.payload['title'] as String,
            description: op.payload['description'] as String,
            status: TaskStatusWire.fromWire(op.payload['status'] as String),
          );
          await _cache.put(updated);
          await _queue.remove(op.opId);
          return true;
        case PendingOpType.delete:
          final id = int.tryParse(op.taskKey);
          if (id != null) {
            await _taskApi.delete(id);
          }
          await _cache.delete(op.taskKey);
          await _queue.remove(op.opId);
          return true;
      }
    } catch (e) {
      final apiException = toApiException(e);
      if (!apiException.isNetworkError && apiException.statusCode == 404) {
        // Task already gone server-side: nothing more to do.
        await _cache.delete(op.taskKey);
        await _queue.remove(op.opId);
        return true;
      }
      await _queue.incrementRetry(op.opId);
      return false;
    }
  }
}

enum SyncResult { success, partialFailure, alreadyRunning }
