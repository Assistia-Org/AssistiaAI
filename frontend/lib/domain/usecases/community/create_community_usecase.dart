import '../../entities/community/community.dart';
import '../../repositories/community/community_repository.dart';

class CreateCommunityUseCase {
  final CommunityRepository repository;

  CreateCommunityUseCase(this.repository);

  Future<Community> call({
    required String name,
    required String type,
    String? description,
  }) {
    return repository.createCommunity(
      name: name,
      type: type,
      description: description,
    );
  }
}
