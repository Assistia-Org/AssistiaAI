import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';
import '../../data/datasources/task/task_remote_data_source.dart';
import '../../data/repositories/task/task_repository_impl.dart';
import '../../data/models/task/task_model.dart';

// --- Dependency Injection ---

final taskRemoteDataSourceProvider = FutureProvider<TaskRemoteDataSource>((
  ref,
) async {
  final prefs = await ref.watch(sharedPrefsProvider.future);
  final client = ref.watch(httpClientProvider);
  return TaskRemoteDataSource(client: client, sharedPreferences: prefs);
});

final taskRepositoryProvider = FutureProvider<TaskRepositoryImpl>((ref) async {
  final remoteDataSource = await ref.watch(taskRemoteDataSourceProvider.future);
  return TaskRepositoryImpl(remoteDataSource);
});

// --- State Management ---

class TaskLoadingNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setLoading(bool val) {
    state = val;
  }
}

final taskLoadingProvider = NotifierProvider<TaskLoadingNotifier, bool>(() {
  return TaskLoadingNotifier();
});

class TaskController {
  final Ref ref;

  TaskController(this.ref);

  Future<TaskModel> createTask(TaskModel task) async {
    ref.read(taskLoadingProvider.notifier).setLoading(true);
    try {
      final repository = await ref.read(taskRepositoryProvider.future);
      return await repository.createTask(task);
    } finally {
      ref.read(taskLoadingProvider.notifier).setLoading(false);
    }
  }

  Future<List<TaskModel>> getMyTasks(String userId) async {
    final repository = await ref.read(taskRepositoryProvider.future);
    return await repository.getTasksByUserId(userId);
  }

  Future<TaskModel> updateTaskStatus(String taskId, String status) async {
    ref.read(taskLoadingProvider.notifier).setLoading(true);
    try {
      final repository = await ref.read(taskRepositoryProvider.future);
      return await repository.updateTaskStatus(taskId, status);
    } finally {
      ref.read(taskLoadingProvider.notifier).setLoading(false);
    }
  }
}

final taskControllerProvider = Provider<TaskController>((ref) {
  return TaskController(ref);
});
