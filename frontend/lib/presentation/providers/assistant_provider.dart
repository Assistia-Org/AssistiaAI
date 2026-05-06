import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';
import '../../data/datasources/assistant/assistant_remote_data_source.dart';
import '../../data/repositories/assistant/assistant_repository_impl.dart';
import '../../data/models/assistant/assistant_message_model.dart';
import 'daily_program_provider.dart';

// --- Dependency Injection ---

final assistantRemoteDataSourceProvider = FutureProvider<AssistantRemoteDataSource>((ref) async {
  final prefs = await ref.watch(sharedPrefsProvider.future);
  final client = ref.watch(httpClientProvider);
  return AssistantRemoteDataSource(client: client, sharedPreferences: prefs);
});

final assistantRepositoryProvider = FutureProvider<AssistantRepositoryImpl>((ref) async {
  final remoteDataSource = await ref.watch(assistantRemoteDataSourceProvider.future);
  return AssistantRepositoryImpl(remoteDataSource: remoteDataSource);
});

// --- State Management ---

class AssistantState {
  final List<AssistantMessageModel> history;
  final bool isLoading;
  final String? error;

  AssistantState({
    required this.history,
    this.isLoading = false,
    this.error,
  });

  AssistantState copyWith({
    List<AssistantMessageModel>? history,
    bool? isLoading,
    String? error,
  }) {
    return AssistantState(
      history: history ?? this.history,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AssistantNotifier extends Notifier<AssistantState> {
  @override
  AssistantState build() {
    return AssistantState(history: []);
  }

  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    // Kullanıcının mesajını ekle
    final userMsg = AssistantMessageModel(role: 'user', content: message);
    state = state.copyWith(
      history: [...state.history, userMsg],
      isLoading: true,
      error: null,
    );

    try {
      final repository = await ref.read(assistantRepositoryProvider.future);
      // Yerel saat dilimi ofsetini oluştur (örn: +03:00)
      final duration = DateTime.now().timeZoneOffset;
      final sign = duration.isNegative ? '-' : '+';
      final hours = duration.inHours.abs().toString().padLeft(2, '0');
      final minutes = (duration.inMinutes.abs() % 60).toString().padLeft(2, '0');
      final tzOffset = '$sign$hours:$minutes';

      // backend'den dönen response -> { reply: "...", action_performed: "...", result: {...}, needs_clarification: true/false }
      final response = await repository.sendChatMessage(
        message: message,
        history: state.history.sublist(0, state.history.length - 1), // Son mesaj userMsg, onu API message olarak gönderiyor
        timezoneOffset: tzOffset,
      );

      String replyText = response['reply'] ?? '';
      final String? actionPerformed = response['action_performed'];
      
      if (replyText.trim().isEmpty) {
        if (actionPerformed != null && actionPerformed.isNotEmpty) {
          replyText = 'İşleminizi başarıyla tamamladım! ✓';
        } else {
          replyText = 'İsteğinizi şu an işleyemiyorum, lütfen tekrar deneyin.';
        }
      }

      final assistantMsg = AssistantMessageModel(role: 'assistant', content: replyText);
      state = state.copyWith(
        history: [...state.history, assistantMsg],
        isLoading: false,
      );
      
      // Eğer asistan bir aksiyon almışsa arka plandaki listeyi yenile
      if (actionPerformed != null) {
        ref.invalidate(dailyProgramByDateProvider);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void clearHistory() {
    state = AssistantState(history: []);
  }
}

final assistantProvider = NotifierProvider<AssistantNotifier, AssistantState>(() {
  return AssistantNotifier();
});

final dailyGreetingProvider = FutureProvider.family<String, String?>((ref, targetDate) async {
  final repository = await ref.watch(assistantRepositoryProvider.future);
  return repository.getDailyGreeting(targetDate: targetDate);
});
