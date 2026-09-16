import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:task_manager/core/api/api_exception.dart';
import 'package:task_manager/core/sync/pending_ops_queue.dart';
import 'package:task_manager/core/sync/sync_service.dart';
import 'package:task_manager/core/sync/task_cache.dart';

import '../helpers/fakes.dart';
import '../helpers/hive_test_helper.dart';

void main() {
  late MockTaskApi taskApi;
  late PendingOpsQueue queue;
  late TaskCache cache;
  late SyncService sync;

  setUpAll(() {
    registerFakeFallbackValues();
  });

  setUp(() async {
    await HiveTestHelper.setUp();
    taskApi = MockTaskApi();
    queue = PendingOpsQueue();
    cache = TaskCache();
    sync = SyncService(taskApi: taskApi, queue: queue, cache: cache);
  });

  tearDown(() async {
    await HiveTestHelper.tearDown();
  });

  test(
    'drains a queued create and reconciles the local id with the server id',
    () async {
      final localTask = buildTask(
        localId: 'local-1',
        id: null,
        title: 'Buy milk',
      );
      await cache.put(localTask);
      await queue.enqueueCreate('local-1', localTask.toRequestJson());

      final serverTask = buildTask(
        localId: 'server-1',
        id: 100,
        title: 'Buy milk',
      );
      when(
        () => taskApi.create(
          title: any(named: 'title'),
          description: any(named: 'description'),
          status: any(named: 'status'),
        ),
      ).thenAnswer((_) async => serverTask);

      final result = await sync.drain();

      expect(result, SyncResult.success);
      expect(queue.pendingCount, 0);
      expect(
        cache.get('local-1'),
        isNull,
        reason: 'old local-id entry should be gone',
      );
      expect(cache.get('100')?.id, 100);
    },
  );

  test('drains a queued update against the reconciled server id', () async {
    final task = buildTask(localId: '100', id: 100, title: 'Old title');
    await cache.put(task);
    await queue.enqueueUpdate('100', {
      'title': 'New title',
      'description': '',
      'status': 'TODO',
    });

    final updated = buildTask(localId: '100', id: 100, title: 'New title');
    when(
      () => taskApi.update(
        100,
        title: any(named: 'title'),
        description: any(named: 'description'),
        status: any(named: 'status'),
      ),
    ).thenAnswer((_) async => updated);

    final result = await sync.drain();

    expect(result, SyncResult.success);
    expect(queue.pendingCount, 0);
    expect(cache.get('100')?.title, 'New title');
  });

  test('drains a queued delete', () async {
    final task = buildTask(localId: '100', id: 100, title: 'Gone soon');
    await cache.put(task);
    await queue.enqueueDelete('100');

    when(() => taskApi.delete(100)).thenAnswer((_) async {});

    final result = await sync.drain();

    expect(result, SyncResult.success);
    expect(queue.pendingCount, 0);
    expect(cache.get('100'), isNull);
  });

  test(
    'a network failure stops the drain and keeps the op queued for retry',
    () async {
      await queue.enqueueCreate('local-1', {
        'title': 'A',
        'description': '',
        'status': 'TODO',
      });
      await queue.enqueueCreate('local-2', {
        'title': 'B',
        'description': '',
        'status': 'TODO',
      });

      when(
        () => taskApi.create(
          title: any(named: 'title'),
          description: any(named: 'description'),
          status: any(named: 'status'),
        ),
      ).thenThrow(
        DioException(requestOptions: RequestOptions(path: '/api/tasks')),
      );

      final result = await sync.drain();

      expect(result, SyncResult.partialFailure);
      expect(
        queue.pendingCount,
        2,
        reason: 'nothing should be dropped on network failure',
      );
      expect(queue.all.first.retryCount, 1);
      verify(
        () => taskApi.create(
          title: any(named: 'title'),
          description: any(named: 'description'),
          status: any(named: 'status'),
        ),
      ).called(1);
    },
  );

  test(
    'a 404 on an update is treated as resolved and the op is dropped',
    () async {
      await queue.enqueueUpdate('55', {
        'title': 'x',
        'description': '',
        'status': 'TODO',
      });

      when(
        () => taskApi.update(
          55,
          title: any(named: 'title'),
          description: any(named: 'description'),
          status: any(named: 'status'),
        ),
      ).thenThrow(const ApiException('Not found', statusCode: 404));

      final result = await sync.drain();

      expect(result, SyncResult.success);
      expect(queue.pendingCount, 0);
    },
  );
}
