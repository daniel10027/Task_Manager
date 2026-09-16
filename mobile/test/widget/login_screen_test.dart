import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:task_manager/core/api/api_exception.dart';
import 'package:task_manager/models/user.dart';
import 'package:task_manager/screens/auth/login_screen.dart';
import 'package:task_manager/screens/tasks/task_list_screen.dart';
import 'package:task_manager/state/auth_provider.dart';
import 'package:task_manager/state/task_list_provider.dart';

import '../helpers/fakes.dart';
import '../helpers/pump_helpers.dart';

void main() {
  late MockAuthApi authApi;
  late MockSecureStorageService secureStorage;
  late MockTaskRepository taskRepository;
  late MockConnectivityService connectivity;
  late MockPendingOpsQueue pendingOpsQueue;

  setUpAll(() {
    registerFakeFallbackValues();
  });

  setUp(() {
    authApi = MockAuthApi();
    secureStorage = MockSecureStorageService();
    when(() => secureStorage.writeToken(any())).thenAnswer((_) async {});
    when(() => secureStorage.writeUserJson(any())).thenAnswer((_) async {});

    taskRepository = MockTaskRepository();
    connectivity = MockConnectivityService();
    pendingOpsQueue = MockPendingOpsQueue();
    when(() => connectivity.onStatusChange)
        .thenAnswer((_) => const Stream.empty());
    when(() => connectivity.isOnline).thenReturn(true);
    when(() => connectivity.refresh()).thenAnswer((_) async => true);
    when(() => pendingOpsQueue.watch()).thenAnswer((_) => const Stream.empty());
    when(() => pendingOpsQueue.pendingCount).thenReturn(0);
    when(
      () => taskRepository.fetchTasks(
        status: any(named: 'status'),
        search: any(named: 'search'),
      ),
    ).thenAnswer((_) async => []);
    when(() => taskRepository.sync()).thenAnswer((_) async {});
  });

  Widget buildApp() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) =>
              AuthProvider(authApi: authApi, secureStorage: secureStorage),
        ),
        ChangeNotifierProvider<TaskListProvider>(
          create: (_) => TaskListProvider(
            repository: taskRepository,
            connectivity: connectivity,
            pendingOpsQueue: pendingOpsQueue,
          ),
        ),
      ],
      child: const MaterialApp(home: LoginScreen()),
    );
  }

  testWidgets('shows a validation error for an invalid email', (tester) async {
    await tester.pumpWidget(buildApp());

    await tester.enterText(
      find.byKey(const Key('login_email_field')),
      'not-an-email',
    );
    await tester.enterText(
      find.byKey(const Key('login_password_field')),
      'password123',
    );
    await tester.tap(find.byKey(const Key('login_submit_button')));
    await tester.pump();

    expect(find.text('Email invalide'), findsOneWidget);
    verifyNever(
      () => authApi.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    );
  });

  testWidgets('shows a validation error for a too-short password', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());

    await tester.enterText(
      find.byKey(const Key('login_email_field')),
      'jane@doe.com',
    );
    await tester.enterText(
      find.byKey(const Key('login_password_field')),
      'short',
    );
    await tester.tap(find.byKey(const Key('login_submit_button')));
    await tester.pump();

    expect(find.text('Minimum 8 caractères'), findsOneWidget);
    verifyNever(
      () => authApi.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    );
  });

  testWidgets('submits valid credentials and calls the API exactly once', (
    tester,
  ) async {
    when(() => authApi.login(email: 'jane@doe.com', password: 'Sup3rSecret!'))
        .thenAnswer(
          (_) async => const AuthResponse(
            token: 'jwt-token',
            user: User(id: 1, email: 'jane@doe.com', fullName: 'Jane Doe'),
          ),
        );

    await tester.pumpWidget(buildApp());

    await tester.enterText(
      find.byKey(const Key('login_email_field')),
      'jane@doe.com',
    );
    await tester.enterText(
      find.byKey(const Key('login_password_field')),
      'Sup3rSecret!',
    );
    await tester.tap(find.byKey(const Key('login_submit_button')));
    await settle(tester);

    verify(() => authApi.login(email: 'jane@doe.com', password: 'Sup3rSecret!'))
        .called(1);
    expect(find.byType(TaskListScreen), findsOneWidget);
  });

  testWidgets('surfaces an API error via a SnackBar', (tester) async {
    when(
      () => authApi.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(const ApiException('Identifiants invalides'));

    await tester.pumpWidget(buildApp());

    await tester.enterText(
      find.byKey(const Key('login_email_field')),
      'jane@doe.com',
    );
    await tester.enterText(
      find.byKey(const Key('login_password_field')),
      'Sup3rSecret!',
    );
    await tester.tap(find.byKey(const Key('login_submit_button')));
    await tester.pumpAndSettle();

    expect(find.text('Identifiants invalides'), findsOneWidget);
  });
}
