import '../../repositories/community/community_repository.dart';

class DeleteCommunityUseCase {
  final CommunityRepository repository;

  DeleteCommunityUseCase(this.repository);

  Future<void> call(String id) {
    return repository.deleteCommunity(id);
  }
}
