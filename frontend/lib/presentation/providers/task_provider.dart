import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';
import '../../data/datasources/task_remote_data_source.dart';
import '../../data/repositories/task_repository_impl.dart';
import '../../data/models/task_model.dart';

// --- Dependency Injection ---

final taskRemoteDataSourceProvider = Provider<TaskRemoteDataSource>((ref) {
  return TaskRemoteDataSource();
});

final taskRepositoryProvider = Provider<TaskRepositoryImpl>((ref) {
  final remoteDataSource = ref.watch(taskRemoteDataSourceProvider);
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
      final repository = ref.read(taskRepositoryProvider);
      return await repository.createTask(task);
    } finally {
      ref.read(taskLoadingProvider.notifier).setLoading(false);
    }
  }

  Future<List<TaskModel>> getMyTasks(String userId) async {
    final repository = ref.read(taskRepositoryProvider);
    return await repository.getTasksByUserId(userId);
  }
}

final taskControllerProvider = Provider<TaskController>((ref) {
  return TaskController(ref);
});
