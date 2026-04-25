import '../../datasources/task/task_remote_data_source.dart';
import '../../models/task/task_model.dart';
import '../../../domain/repositories/task/task_repository.dart';

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

  @override
  Future<TaskModel> updateTaskStatus(String taskId, String status) {
    return remoteDataSource.updateTaskStatus(taskId, status);
  }

  @override
  Future<void> deleteTask(String taskId) {
    return remoteDataSource.deleteTask(taskId);
  }
}
