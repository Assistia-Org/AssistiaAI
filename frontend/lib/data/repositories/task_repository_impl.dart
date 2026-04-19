import '../datasources/task_remote_data_source.dart';
import '../models/task_model.dart';
import '../../domain/repositories/task_repository.dart';

class TaskRepositoryImpl implements TaskRepository {
  final TaskRemoteDataSource remoteDataSource;

  TaskRepositoryImpl(this.remoteDataSource);

  @override
  Future<TaskModel> createTask(TaskModel task) {
    return remoteDataSource.createTask(task);
  }

  @override
  Future<List<TaskModel>> getTasksByUserId(String userId) {
    return remoteDataSource.getTasksByUserId(userId);
  }
}
