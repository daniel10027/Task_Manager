import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:task_manager/core/sync/pending_ops_queue.dart';
import 'package:task_manager/core/sync/sync_service.dart';
import 'package:task_manager/core/sync/task_cache.dart';
import 'package:task_manager/core/sync/task_repository.dart';
import 'package:task_manager/models/task.dart';

import '../helpers/fakes.dart';
import '../helpers/hive_test_helper.dart';

void main() {
  late MockTaskApi taskApi;
  late MockConnectivityService connectivity;
  late TaskCache cache;
  late PendingOpsQueue queue;
  late SyncService syncService;
  late TaskRepository repository;

  setUpAll(() {
    registerFakeFallbackValues();
  });

  setUp(() async {
    await HiveTestHelper.setUp();
    taskApi = MockTaskApi();
    connectivity = MockConnectivityService();
    cache = TaskCache();
    queue = PendingOpsQueue();
    syncService = SyncService(taskApi: taskApi, queue: queue, cache: cache);
    repository = TaskRepository(
      taskApi: taskApi,
      connectivity: connectivity,
      cache: cache,
      queue: queue,
      syncService: syncService,
    );
  });

  tearDown(() async {
    await HiveTestHelper.tearDown();
  });

  test('creating a task while offline writes local cache + enqueues a create, without calling the API', () async {
    when(() => connectivity.isOnline).thenReturn(false);

    final created = await repository.createTask(
      title: 'Buy milk',
      description: '',
      status: TaskStatus.todo,
    );

    expect(created.isSynced, isFalse);
    expect(repository.pendingCount, 1);
    expect(repository.readCached().single.title, 'Buy milk');
    verifyNever(() => taskApi.create(
          title: any(named: 'title'),
          description: any(named: 'description'),
          status: any(named: 'status'),
        ));
  });

  test('reconnecting and syncing drains the queue and reconciles the id', () async {
    when(() => connectivity.isOnline).thenReturn(false);
    final created = await repository.createTask(
      title: 'Buy milk',
      description: '',
      status: TaskStatus.todo,
    );
    expect(repository.pendingCount, 1);

    // Connectivity returns.
    when(() => connectivity.isOnline).thenReturn(true);
    final serverTask = buildTask(localId: 'x', id: 55, title: 'Buy milk');
    when(() => taskApi.create(
          title: any(named: 'title'),
          description: any(named: 'description'),
          status: any(named: 'status'),
        )).thenAnswer((_) async => serverTask);

    await repository.sync();

    expect(repository.pendingCount, 0);
    final cached = repository.readCached();
    expect(cached.single.id, 55);
    expect(cached.any((t) => t.cacheKey == created.cacheKey), isFalse,
        reason: 'the temporary local-id entry should have been replaced');
  });

  test('creating while online calls the API directly and does not enqueue anything', () async {
    when(() => connectivity.isOnline).thenReturn(true);
    final serverTask = buildTask(localId: 'x', id: 7, title: 'Online task');
    when(() => taskApi.create(
          title: any(named: 'title'),
          description: any(named: 'description'),
          status: any(named: 'status'),
        )).thenAnswer((_) async => serverTask);

    final created = await repository.createTask(
      title: 'Online task',
      description: '',
      status: TaskStatus.todo,
    );

    expect(created.id, 7);
    expect(repository.pendingCount, 0);
  });
}
