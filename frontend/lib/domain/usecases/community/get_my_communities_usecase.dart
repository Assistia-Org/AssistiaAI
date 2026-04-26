import '../../entities/community/community.dart';
import '../../repositories/community/community_repository.dart';

class GetMyCommunitiesUseCase {
  final CommunityRepository repository;

  GetMyCommunitiesUseCase(this.repository);

  Future<List<Community>> call() {
    return repository.getMyCommunities();
  }
}
