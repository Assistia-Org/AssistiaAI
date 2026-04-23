import '../../entities/community/community.dart';
import '../../repositories/community/community_repository.dart';

class GetCommunityByIdUseCase {
  final CommunityRepository repository;

  GetCommunityByIdUseCase(this.repository);

  Future<Community> call(String id) {
    return repository.getCommunityById(id);
  }
}
