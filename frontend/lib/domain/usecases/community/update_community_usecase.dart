import '../../entities/community/community.dart';
import '../../repositories/community/community_repository.dart';

class UpdateCommunityUseCase {
  final CommunityRepository repository;

  UpdateCommunityUseCase(this.repository);

  Future<Community> call({
    required String id,
    String? name,
    String? type,
    List<CommunityMember>? members,
  }) {
    return repository.updateCommunity(
      id: id,
      name: name,
      type: type,
      members: members,
    );
  }
}
