import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../storage/hive_boxes.dart';
import 'pending_operation.dart';

const _uuid = Uuid();

/// Manages the pending-mutations Hive box, applying the coalescing rules
/// described in the brief so a task never gets more than one queued
/// operation at a time:
///
/// - queue a create, then edit again offline -> the create's payload is
///   updated in place (still a single create, sent once).
/// - queue an update, then edit again offline -> payload replaced in place.
/// - delete a task whose create never synced -> the create is cancelled
///   entirely (nothing to send, the task never existed server-side).
/// - delete a task that has a pending update -> the update is replaced by a
///   delete (final state wins).
class PendingOpsQueue {
  Box<PendingOperation> get _box => HiveBoxes.pendingOpsBox;

  /// All queued operations, oldest first (insertion order).
  List<PendingOperation> get all => _box.values.toList();

  int get pendingCount => _box.length;

  Stream<void> watch() => _box.watch().map((_) {});

  PendingOperation? _findFor(String taskKey) {
    for (final op in _box.values) {
      if (op.taskKey == taskKey) return op;
    }
    return null;
  }

  String? _hiveKeyFor(String opId) {
    for (final entry in _box.toMap().entries) {
      if (entry.value.opId == opId) return entry.key as String;
    }
    return null;
  }

  Future<void> enqueueCreate(String taskKey, Map<String, dynamic> payload) {
    final op = PendingOperation(
      opId: _uuid.v4(),
      type: PendingOpType.create,
      taskKey: taskKey,
      payload: payload,
      createdAt: DateTime.now(),
    );
    return _box.put(op.opId, op);
  }

  Future<void> enqueueUpdate(String taskKey, Map<String, dynamic> payload) async {
    final existing = _findFor(taskKey);
    if (existing != null) {
      // A create or update already queued for this task: coalesce by
      // replacing the payload in place, keeping the original op type.
      await _box.put(existing.opId, existing.copyWith(payload: payload));
      return;
    }
    final op = PendingOperation(
      opId: _uuid.v4(),
      type: PendingOpType.update,
      taskKey: taskKey,
      payload: payload,
      createdAt: DateTime.now(),
    );
    await _box.put(op.opId, op);
  }

  /// Returns true if the delete cancelled out an unsynced create (i.e. the
  /// caller does not need to keep the task around at all, even locally).
  Future<bool> enqueueDelete(String taskKey) async {
    final existing = _findFor(taskKey);
    if (existing != null && existing.type == PendingOpType.create) {
      // Task never made it to the server: just drop the queued create.
      await _box.delete(existing.opId);
      return true;
    }
    if (existing != null && existing.type == PendingOpType.update) {
      await _box.put(
        existing.opId,
        existing.copyWith(type: PendingOpType.delete, payload: const {}),
      );
      return false;
    }
    final op = PendingOperation(
      opId: _uuid.v4(),
      type: PendingOpType.delete,
      taskKey: taskKey,
      payload: const {},
      createdAt: DateTime.now(),
    );
    await _box.put(op.opId, op);
    return false;
  }

  Future<void> remove(String opId) async {
    final key = _hiveKeyFor(opId);
    if (key != null) await _box.delete(key);
  }

  /// Re-keys a queued operation after its task's local id has been
  /// reconciled with a server id (used by [SyncService]).
  Future<void> rekey(String opId, String newTaskKey) async {
    final key = _hiveKeyFor(opId);
    if (key == null) return;
    final op = _box.get(key)!;
    await _box.put(key, PendingOperation(
      opId: op.opId,
      type: op.type,
      taskKey: newTaskKey,
      payload: op.payload,
      createdAt: op.createdAt,
      retryCount: op.retryCount,
    ));
  }

  Future<void> incrementRetry(String opId) async {
    final key = _hiveKeyFor(opId);
    if (key == null) return;
    final op = _box.get(key)!;
    await _box.put(key, op.copyWith(retryCount: op.retryCount + 1));
  }
}
