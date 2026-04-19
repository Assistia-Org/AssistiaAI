import '../../models/daily_program/daily_program_model.dart';
import '../../datasources/daily_program/daily_program_remote_data_source.dart';

abstract class DailyProgramRepository {
  Future<DailyProgramModel> getProgramByDate(String dateStr);
}

class DailyProgramRepositoryImpl implements DailyProgramRepository {
  final DailyProgramRemoteDataSource remoteDataSource;

  DailyProgramRepositoryImpl(this.remoteDataSource);

  @override
  Future<DailyProgramModel> getProgramByDate(String dateStr) {
    return remoteDataSource.getProgramByDate(dateStr);
  }
}
