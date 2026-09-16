import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/task.dart';
import '../../state/auth_provider.dart';
import '../../state/task_list_provider.dart';
import '../../theme/app_spacing.dart';
import '../auth/login_screen.dart';
import 'task_form_sheet.dart';
import 'widgets/empty_state.dart';
import 'widgets/status_filter_chips.dart';
import 'widgets/status_pill.dart';
import 'widgets/task_list_shimmer.dart';
import 'widgets/task_tile.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  Timer? _debounce;
  late final AnimationController _fabController;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      lowerBound: 0,
      upperBound: 0.125,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskListProvider>().init();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    _fabController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      context.read<TaskListProvider>().setSearch(value);
    });
  }

  Future<void> _openCreateForm() async {
    await _fabController.forward();
    await _fabController.reverse();
    if (!mounted) return;
    final result = await showTaskFormSheet(context);
    if (result == null || !mounted) return;
    await context.read<TaskListProvider>().createTask(
          title: result.title,
          description: result.description,
          status: result.status,
        );
  }

  Future<void> _openEditForm(Task task) async {
    final result = await showTaskFormSheet(context, task: task);
    if (result == null || !mounted) return;
    await context.read<TaskListProvider>().updateTask(
          task,
          title: result.title,
          description: result.description,
          status: result.status,
        );
  }

  Future<void> _deleteWithUndo(Task task) async {
    final provider = context.read<TaskListProvider>();
    await provider.deleteTask(task);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('« ${task.title} » supprimée'),
        action: SnackBarAction(
          label: 'Annuler',
          onPressed: () {
            provider.createTask(
              title: task.title,
              description: task.description,
              status: task.status,
            );
          },
        ),
      ),
    );
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskListProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes tâches'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: Center(
              child: StatusPill(isOnline: provider.isOnline, pendingCount: provider.pendingCount),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
            child: TextField(
              key: const Key('task_search_field'),
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: const InputDecoration(
                hintText: 'Rechercher une tâche...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: StatusFilterChips(
              selected: provider.filterStatus,
              onChanged: (status) => provider.setFilter(status),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(child: _buildBody(provider)),
        ],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _fabController,
        builder: (context, child) {
          final scale = 1 - (_fabController.value * 0.5);
          return Transform.rotate(
            angle: _fabController.value * 3.14159,
            child: Transform.scale(scale: scale, child: child),
          );
        },
        child: FloatingActionButton(
          key: const Key('add_task_fab'),
          onPressed: _openCreateForm,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildBody(TaskListProvider provider) {
    if (provider.loadState == ListLoadState.loading && provider.tasks.isEmpty) {
      return const TaskListShimmer();
    }
    if (provider.tasks.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => provider.load(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: 420,
              child: EmptyState(
                title: provider.search.isNotEmpty || provider.filterStatus != null
                    ? 'Aucune tâche ne correspond'
                    : 'Aucune tâche pour le moment',
                message: provider.search.isNotEmpty || provider.filterStatus != null
                    ? 'Essayez un autre filtre ou une autre recherche.'
                    : 'Appuyez sur + pour créer votre première tâche.',
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      key: const Key('task_list_refresh'),
      onRefresh: () => provider.load(),
      child: ListView.builder(
        key: const Key('task_list_view'),
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, 96),
        itemCount: provider.tasks.length,
        itemBuilder: (context, index) {
          final task = provider.tasks[index];
          return TaskTile(
            task: task,
            index: index,
            onTap: () => _openEditForm(task),
            onDismissed: () => _deleteWithUndo(task),
          );
        },
      ),
    );
  }
}
