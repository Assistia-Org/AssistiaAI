import '../../../data/models/assistant/assistant_message_model.dart';

abstract class AssistantRepository {
  Future<Map<String, dynamic>> sendChatMessage({
    required String message,
    required List<AssistantMessageModel> history,
    required String timezoneOffset,
  });
}
