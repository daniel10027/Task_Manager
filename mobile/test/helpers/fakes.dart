import 'package:mocktail/mocktail.dart';
import 'package:task_manager/core/api/auth_api.dart';
import 'package:task_manager/core/api/task_api.dart';
import 'package:task_manager/core/storage/secure_storage_service.dart';
import 'package:task_manager/core/sync/connectivity_service.dart';
import 'package:task_manager/core/sync/pending_ops_queue.dart';
import 'package:task_manager/core/sync/task_repository.dart';
import 'package:task_manager/models/task.dart';

class MockAuthApi extends Mock implements AuthApi {}

class MockTaskApi extends Mock implements TaskApi {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

class MockTaskRepository extends Mock implements TaskRepository {}

class MockConnectivityService extends Mock implements ConnectivityService {}

class MockPendingOpsQueue extends Mock implements PendingOpsQueue {}

class FakeTask extends Fake implements Task {}

void registerFakeFallbackValues() {
  registerFallbackValue(TaskStatus.todo);
  registerFallbackValue(FakeTask());
}

Task buildTask({
  required String localId,
  int? id,
  String title = 'Task',
  String description = '',
  TaskStatus status = TaskStatus.todo,
  DateTime? createdAt,
}) {
  final at = createdAt ?? DateTime(2026, 9, 16);
  return Task(
    localId: localId,
    id: id,
    title: title,
    description: description,
    status: status,
    createdAt: at,
    updatedAt: at,
  );
}
