import 'package:hive/hive.dart';

/// Task status as defined by CONTRACT.md: TODO | IN_PROGRESS | DONE.
enum TaskStatus { todo, inProgress, done }

extension TaskStatusWire on TaskStatus {
  /// The exact string used on the wire (CONTRACT.md).
  String get wire {
    switch (this) {
      case TaskStatus.todo:
        return 'TODO';
      case TaskStatus.inProgress:
        return 'IN_PROGRESS';
      case TaskStatus.done:
        return 'DONE';
    }
  }

  /// Short French label for UI chips/pills.
  String get label {
    switch (this) {
      case TaskStatus.todo:
        return 'À faire';
      case TaskStatus.inProgress:
        return 'En cours';
      case TaskStatus.done:
        return 'Terminé';
    }
  }

  static TaskStatus fromWire(String value) {
    switch (value) {
      case 'TODO':
        return TaskStatus.todo;
      case 'IN_PROGRESS':
        return TaskStatus.inProgress;
      case 'DONE':
        return TaskStatus.done;
      default:
        throw ArgumentError('Unknown task status: $value');
    }
  }
}

/// A task, cached locally in Hive.
///
/// [localId] is a client-generated uuid that is always present, used as a
/// stable Hive key / Flutter widget key even before the task has a server
/// [id]. [id] is null until the task has been created on the server (i.e.
/// while a create operation is still pending in the offline queue).
class Task {
  final String localId;
  final int? id;
  final String title;
  final String description;
  final TaskStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Task({
    required this.localId,
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Stable key for caching / list widgets: server id when synced, else the
  /// client-generated local id.
  String get cacheKey => id?.toString() ?? localId;

  bool get isSynced => id != null;

  factory Task.fromJson(Map<String, dynamic> json, {String? localId}) {
    return Task(
      localId: localId ?? json['id'].toString(),
      id: json['id'] as int,
      title: json['title'] as String,
      description: (json['description'] as String?) ?? '',
      status: TaskStatusWire.fromWire(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'status': status.wire,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  /// Request body for POST/PUT per CONTRACT.md.
  Map<String, dynamic> toRequestJson() => {
    'title': title,
    'description': description,
    'status': status.wire,
  };

  Task copyWith({
    String? localId,
    int? id,
    bool clearId = false,
    String? title,
    String? description,
    TaskStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Task(
      localId: localId ?? this.localId,
      id: clearId ? null : (id ?? this.id),
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class TaskStatusAdapter extends TypeAdapter<TaskStatus> {
  @override
  final int typeId = 1;

  @override
  TaskStatus read(BinaryReader reader) {
    final index = reader.readByte();
    return TaskStatus.values[index];
  }

  @override
  void write(BinaryWriter writer, TaskStatus obj) {
    writer.writeByte(obj.index);
  }
}

class TaskAdapter extends TypeAdapter<Task> {
  @override
  final int typeId = 0;

  @override
  Task read(BinaryReader reader) {
    final numFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numFields; i++) reader.readByte(): reader.read(),
    };
    return Task(
      localId: fields[0] as String,
      id: fields[1] as int?,
      title: fields[2] as String,
      description: fields[3] as String,
      status: fields[4] as TaskStatus,
      createdAt: fields[5] as DateTime,
      updatedAt: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Task obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.localId)
      ..writeByte(1)
      ..write(obj.id)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.status)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.updatedAt);
  }
}
