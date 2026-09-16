import 'package:hive/hive.dart';

/// The kind of mutation recorded while offline.
enum PendingOpType { create, update, delete }

/// A single queued mutation, to be replayed against the API once
/// connectivity returns.
///
/// [taskKey] is the [Task.cacheKey] this operation applies to (server id
/// once known, otherwise the client-generated local id). Operations for the
/// same [taskKey] are coalesced by [PendingOpsQueue] so that e.g. a create
/// followed by an offline edit results in a single create carrying the
/// latest data, rather than two network calls.
class PendingOperation {
  final String opId;
  final PendingOpType type;
  final String taskKey;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int retryCount;

  const PendingOperation({
    required this.opId,
    required this.type,
    required this.taskKey,
    required this.payload,
    required this.createdAt,
    this.retryCount = 0,
  });

  PendingOperation copyWith({
    PendingOpType? type,
    Map<String, dynamic>? payload,
    int? retryCount,
  }) {
    return PendingOperation(
      opId: opId,
      type: type ?? this.type,
      taskKey: taskKey,
      payload: payload ?? this.payload,
      createdAt: createdAt,
      retryCount: retryCount ?? this.retryCount,
    );
  }
}

class PendingOpTypeAdapter extends TypeAdapter<PendingOpType> {
  @override
  final int typeId = 3;

  @override
  PendingOpType read(BinaryReader reader) {
    return PendingOpType.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, PendingOpType obj) {
    writer.writeByte(obj.index);
  }
}

class PendingOperationAdapter extends TypeAdapter<PendingOperation> {
  @override
  final int typeId = 2;

  @override
  PendingOperation read(BinaryReader reader) {
    final numFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numFields; i++) reader.readByte(): reader.read(),
    };
    return PendingOperation(
      opId: fields[0] as String,
      type: fields[1] as PendingOpType,
      taskKey: fields[2] as String,
      payload: Map<String, dynamic>.from(fields[3] as Map),
      createdAt: fields[4] as DateTime,
      retryCount: fields[5] as int? ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, PendingOperation obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.opId)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.taskKey)
      ..writeByte(3)
      ..write(obj.payload)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.retryCount);
  }
}
