import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';
import '../../data/datasources/daily_program/daily_program_remote_data_source.dart';
import '../../data/repositories/daily_program/daily_program_repository_impl.dart';
import '../../data/models/daily_program/daily_program_model.dart';

final dailyProgramRemoteDataSourceProvider =
    FutureProvider<DailyProgramRemoteDataSource>((ref) async {
      final prefs = await ref.watch(sharedPrefsProvider.future);
      final client = ref.watch(httpClientProvider);
      return DailyProgramRemoteDataSource(
        client: client,
        sharedPreferences: prefs,
      );
    });

final dailyProgramRepositoryProvider = FutureProvider<DailyProgramRepository>((
  ref,
) async {
  final remoteDataSource = await ref.watch(
    dailyProgramRemoteDataSourceProvider.future,
  );
  return DailyProgramRepositoryImpl(remoteDataSource);
});

// A family provider that fetches the program for a specific date
final dailyProgramByDateProvider =
    FutureProvider.family<DailyProgramModel, String>((ref, dateStr) async {
      final repository = await ref.watch(dailyProgramRepositoryProvider.future);
      return await repository.getProgramByDate(dateStr);
    });
