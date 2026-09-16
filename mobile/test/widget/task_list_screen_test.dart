import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:task_manager/models/task.dart';
import 'package:task_manager/screens/tasks/task_list_screen.dart';
import 'package:task_manager/state/auth_provider.dart';
import 'package:task_manager/state/task_list_provider.dart';

import '../helpers/fakes.dart';
import '../helpers/pump_helpers.dart';

void main() {
  late MockTaskRepository repository;
  late MockConnectivityService connectivity;
  late MockPendingOpsQueue pendingOpsQueue;

  final tasks = [
    buildTask(localId: '1', id: 1, title: 'Buy milk', description: 'From the store'),
    buildTask(localId: '2', id: 2, title: 'Write report', status: TaskStatus.inProgress),
    buildTask(localId: '3', id: 3, title: 'Clean house', status: TaskStatus.done),
  ];

  setUpAll(() {
    registerFakeFallbackValues();
  });

  setUp(() {
    repository = MockTaskRepository();
    connectivity = MockConnectivityService();
    pendingOpsQueue = MockPendingOpsQueue();

    when(() => connectivity.onStatusChange).thenAnswer((_) => const Stream.empty());
    when(() => connectivity.isOnline).thenReturn(true);
    when(() => connectivity.refresh()).thenAnswer((_) async => true);
    when(() => pendingOpsQueue.watch()).thenAnswer((_) => const Stream.empty());
    when(() => pendingOpsQueue.pendingCount).thenReturn(0);
    when(() => repository.sync()).thenAnswer((_) async {});

    when(() => repository.fetchTasks(
          status: any(named: 'status'),
          search: any(named: 'search'),
        )).thenAnswer((invocation) async {
      final status = invocation.namedArguments[#status] as TaskStatus?;
      final search = invocation.namedArguments[#search] as String?;
      return tasks.where((t) {
        final matchesStatus = status == null || t.status == status;
        final matchesSearch = search == null ||
            search.isEmpty ||
            t.title.toLowerCase().contains(search.toLowerCase()) ||
            t.description.toLowerCase().contains(search.toLowerCase());
        return matchesStatus && matchesSearch;
      }).toList();
    });
  });

  Widget buildApp() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(
            authApi: MockAuthApi(),
            secureStorage: MockSecureStorageService(),
          ),
        ),
        ChangeNotifierProvider<TaskListProvider>(
          create: (_) => TaskListProvider(
            repository: repository,
            connectivity: connectivity,
            pendingOpsQueue: pendingOpsQueue,
          ),
        ),
      ],
      child: const MaterialApp(home: TaskListScreen()),
    );
  }

  testWidgets('renders the full task list on load', (tester) async {
    await tester.pumpWidget(buildApp());
    await settle(tester);

    expect(find.text('Buy milk'), findsOneWidget);
    expect(find.text('Write report'), findsOneWidget);
    expect(find.text('Clean house'), findsOneWidget);
  });

  testWidgets('filter chips filter the list', (tester) async {
    await tester.pumpWidget(buildApp());
    await settle(tester);

    await tester.tap(find.byKey(const Key('filter_chip_Terminé')));
    await settle(tester);

    expect(find.text('Clean house'), findsOneWidget);
    expect(find.text('Buy milk'), findsNothing);
    expect(find.text('Write report'), findsNothing);
  });

  testWidgets('search field filters the list', (tester) async {
    await tester.pumpWidget(buildApp());
    await settle(tester);

    await tester.enterText(find.byKey(const Key('task_search_field')), 'milk');
    // Flush the search debounce.
    await tester.pump(const Duration(milliseconds: 500));
    await settle(tester);

    expect(find.text('Buy milk'), findsOneWidget);
    expect(find.text('Write report'), findsNothing);
    expect(find.text('Clean house'), findsNothing);
  });

  testWidgets('shows an empty state when no task matches', (tester) async {
    await tester.pumpWidget(buildApp());
    await settle(tester);

    await tester.enterText(find.byKey(const Key('task_search_field')), 'nonexistent');
    await tester.pump(const Duration(milliseconds: 500));
    await settle(tester);

    expect(find.text('Aucune tâche ne correspond'), findsOneWidget);
  });

  testWidgets('shows the online status pill', (tester) async {
    await tester.pumpWidget(buildApp());
    await settle(tester);

    expect(find.text('En ligne'), findsOneWidget);
  });
}
