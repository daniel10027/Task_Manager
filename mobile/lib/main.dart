import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/api/api_client.dart';
import 'core/api/auth_api.dart';
import 'core/api/task_api.dart';
import 'core/storage/hive_boxes.dart';
import 'core/storage/onboarding_prefs.dart';
import 'core/storage/secure_storage_service.dart';
import 'core/sync/connectivity_service.dart';
import 'core/sync/pending_ops_queue.dart';
import 'core/sync/sync_service.dart';
import 'core/sync/task_cache.dart';
import 'core/sync/task_repository.dart';
import 'screens/auth/login_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/tasks/task_list_screen.dart';
import 'state/auth_provider.dart';
import 'state/task_list_provider.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveBoxes.init();

  final secureStorage = SecureStorageService();
  final dio = createApiClient(secureStorage: secureStorage);
  final authApi = AuthApi(dio);
  final taskApi = TaskApi(dio);

  final connectivity = ConnectivityService();
  final taskCache = TaskCache();
  final pendingOpsQueue = PendingOpsQueue();
  final syncService = SyncService(
    taskApi: taskApi,
    queue: pendingOpsQueue,
    cache: taskCache,
  );
  final taskRepository = TaskRepository(
    taskApi: taskApi,
    connectivity: connectivity,
    cache: taskCache,
    queue: pendingOpsQueue,
    syncService: syncService,
  );

  runApp(
    TaskManagerApp(
      secureStorage: secureStorage,
      authApi: authApi,
      connectivity: connectivity,
      pendingOpsQueue: pendingOpsQueue,
      taskRepository: taskRepository,
    ),
  );
}

class TaskManagerApp extends StatelessWidget {
  const TaskManagerApp({
    super.key,
    required this.secureStorage,
    required this.authApi,
    required this.connectivity,
    required this.pendingOpsQueue,
    required this.taskRepository,
  });

  final SecureStorageService secureStorage;
  final AuthApi authApi;
  final ConnectivityService connectivity;
  final PendingOpsQueue pendingOpsQueue;
  final TaskRepository taskRepository;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) =>
              AuthProvider(authApi: authApi, secureStorage: secureStorage)
                ..restoreSession(),
        ),
        ChangeNotifierProvider(
          create: (_) => TaskListProvider(
            repository: taskRepository,
            connectivity: connectivity,
            pendingOpsQueue: pendingOpsQueue,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Task Manager',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const AppGate(),
      ),
    );
  }
}

/// Decides which screen to show first: onboarding (first launch only), the
/// login screen, or the task list if a session was restored.
class AppGate extends StatelessWidget {
  const AppGate({super.key});

  @override
  Widget build(BuildContext context) {
    if (!OnboardingPrefs.seen) {
      return const OnboardingScreen();
    }
    final auth = context.watch<AuthProvider>();
    switch (auth.status) {
      case AuthStatus.unknown:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case AuthStatus.authenticated:
        return const TaskListScreen();
      case AuthStatus.unauthenticated:
        return const LoginScreen();
    }
  }
}
