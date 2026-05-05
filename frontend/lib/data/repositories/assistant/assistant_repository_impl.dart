import '../../../domain/repositories/assistant/assistant_repository.dart';
import '../../datasources/assistant/assistant_remote_data_source.dart';
import '../../models/assistant/assistant_message_model.dart';

class AssistantRepositoryImpl implements AssistantRepository {
  final AssistantRemoteDataSource remoteDataSource;

  AssistantRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Map<String, dynamic>> sendChatMessage({
    required String message,
    required List<AssistantMessageModel> history,
    required String timezoneOffset,
  }) async {
    return await remoteDataSource.sendChatMessage(
      message: message,
      history: history,
      timezoneOffset: timezoneOffset,
    );
  }
}
