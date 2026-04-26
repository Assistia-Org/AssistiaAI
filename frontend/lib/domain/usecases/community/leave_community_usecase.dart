import '../../repositories/community/community_repository.dart';

class LeaveCommunityUseCase {
  final CommunityRepository repository;

  LeaveCommunityUseCase(this.repository);

  Future<void> call(String id) async {
    return await repository.leaveCommunity(id);
  }
}
