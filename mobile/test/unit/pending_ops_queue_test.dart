import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/core/sync/pending_operation.dart';
import 'package:task_manager/core/sync/pending_ops_queue.dart';

import '../helpers/hive_test_helper.dart';

void main() {
  late PendingOpsQueue queue;

  setUp(() async {
    await HiveTestHelper.setUp();
    queue = PendingOpsQueue();
  });

  tearDown(() async {
    await HiveTestHelper.tearDown();
  });

  group('enqueueCreate', () {
    test('adds a single create operation', () async {
      await queue.enqueueCreate('local-1', {'title': 'A'});
      expect(queue.pendingCount, 1);
      expect(queue.all.single.type, PendingOpType.create);
      expect(queue.all.single.taskKey, 'local-1');
    });
  });

  group('coalescing', () {
    test('editing an unsynced create keeps a single create op with the latest payload', () async {
      await queue.enqueueCreate('local-1', {'title': 'first draft'});
      await queue.enqueueUpdate('local-1', {'title': 'second draft'});

      expect(
        queue.pendingCount,
        1,
        reason: 'create + edit must coalesce into one op',
      );
      final op = queue.all.single;
      expect(op.type, PendingOpType.create);
      expect(op.payload['title'], 'second draft');
    });

    test('editing twice while offline keeps a single update op with the latest payload', () async {
      await queue.enqueueUpdate('server-5', {'title': 'v1'});
      await queue.enqueueUpdate('server-5', {'title': 'v2'});

      expect(queue.pendingCount, 1);
      final op = queue.all.single;
      expect(op.type, PendingOpType.update);
      expect(op.payload['title'], 'v2');
    });

    test('deleting a task whose create never synced cancels the create entirely', () async {
      await queue.enqueueCreate('local-2', {'title': 'never synced'});
      final cancelled = await queue.enqueueDelete('local-2');

      expect(cancelled, isTrue);
      expect(
        queue.pendingCount,
        0,
        reason:
            'nothing should be sent for a task that never existed server-side',
      );
    });

    test(
      'deleting a task with a pending update replaces it with a delete op',
      () async {
        await queue.enqueueUpdate('server-7', {'title': 'edited'});
        final cancelled = await queue.enqueueDelete('server-7');

        expect(cancelled, isFalse);
        expect(queue.pendingCount, 1);
        expect(queue.all.single.type, PendingOpType.delete);
      },
    );

    test(
      'deleting a task with no pending op enqueues a plain delete',
      () async {
        final cancelled = await queue.enqueueDelete('server-9');

        expect(cancelled, isFalse);
        expect(queue.pendingCount, 1);
        expect(queue.all.single.type, PendingOpType.delete);
      },
    );
  });

  group('retry / removal', () {
    test(
      'incrementRetry bumps the retry count without dropping the op',
      () async {
        await queue.enqueueCreate('local-3', {'title': 'x'});
        final opId = queue.all.single.opId;

        await queue.incrementRetry(opId);

        expect(
          queue.pendingCount,
          1,
          reason: 'a failed op must be retried, not dropped',
        );
        expect(queue.all.single.retryCount, 1);
      },
    );

    test('remove drops the operation by id', () async {
      await queue.enqueueCreate('local-4', {'title': 'x'});
      final opId = queue.all.single.opId;

      await queue.remove(opId);

      expect(queue.pendingCount, 0);
    });

    test(
      'rekey moves an operation to the reconciled server-side task key',
      () async {
        await queue.enqueueCreate('local-5', {'title': 'x'});
        final opId = queue.all.single.opId;

        await queue.rekey(opId, '42');

        expect(queue.all.single.taskKey, '42');
      },
    );
  });
}
