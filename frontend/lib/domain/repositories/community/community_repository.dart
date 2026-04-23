import '../../entities/community/community.dart';

abstract class CommunityRepository {
  Future<Community> createCommunity({
    required String name,
    required String type,
  });

  Future<List<Community>> getMyCommunities();

  Future<Community> getCommunityById(String id);

  Future<Community> updateCommunity({
    required String id,
    String? name,
    String? type,
    List<CommunityMember>? members,
  });

  Future<void> deleteCommunity(String id);

  Future<void> leaveCommunity(String id);

  Future<void> removeCommunityMember(String communityId, String userId);
}
