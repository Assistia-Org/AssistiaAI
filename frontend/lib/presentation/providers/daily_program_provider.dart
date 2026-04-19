import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';
import '../../data/datasources/daily_program_remote_data_source.dart';
import '../../data/repositories/daily_program_repository_impl.dart';
import '../../data/models/daily_program_model.dart';

final dailyProgramRemoteDataSourceProvider = Provider<DailyProgramRemoteDataSource>((ref) {
  return DailyProgramRemoteDataSource();
});

final dailyProgramRepositoryProvider = Provider<DailyProgramRepository>((ref) {
  final remoteDataSource = ref.watch(dailyProgramRemoteDataSourceProvider);
  return DailyProgramRepositoryImpl(remoteDataSource);
});

// A family provider that fetches the program for a specific date
final dailyProgramByDateProvider = FutureProvider.family<DailyProgramModel, String>((ref, dateStr) async {
  final repository = ref.watch(dailyProgramRepositoryProvider);
  return await repository.getProgramByDate(dateStr);
});
