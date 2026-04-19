import '../../../data/models/task/task_model.dart';

abstract class TaskRepository {
  Future<TaskModel> createTask(TaskModel task);
  Future<List<TaskModel>> getTasksByUserId(String userId);
}
