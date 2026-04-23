import '../../repositories/community/community_repository.dart';

class RemoveCommunityMemberUseCase {
  final CommunityRepository repository;

  RemoveCommunityMemberUseCase(this.repository);

  Future<void> call(String communityId, String userId) async {
    return await repository.removeCommunityMember(communityId, userId);
  }
}
