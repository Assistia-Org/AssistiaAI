import '../../../domain/entities/community/community.dart';
import '../../../domain/repositories/community/community_repository.dart';
import '../../datasources/community/community_remote_data_source.dart';
import '../../models/community/community_model.dart';
import '../../models/user/user_model.dart';

class CommunityRepositoryImpl implements CommunityRepository {
  final CommunityRemoteDataSource remoteDataSource;

  CommunityRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Community> createCommunity({
    required String name,
    required String type,
  }) async {
    return await remoteDataSource.createCommunity(name: name, type: type);
  }

  @override
  Future<List<Community>> getMyCommunities() async {
    return await remoteDataSource.getMyCommunities();
  }

  @override
  Future<Community> getCommunityById(String id) async {
    return await remoteDataSource.getCommunityById(id);
  }

  @override
  Future<Community> updateCommunity({
    required String id,
    String? name,
    String? type,
    List<CommunityMember>? members,
  }) async {
    List<CommunityMemberModel>? memberModels;
    if (members != null) {
      memberModels = members.map((m) {
        final u = m.user;
        return CommunityMemberModel(
          user: u is UserModel
              ? u
              : UserModel(
                  id: u.id,
                  username: u.username,
                  email: u.email,
                  displayName: u.displayName,
                  avatarUrl: u.avatarUrl,
                ),
          role: m.role,
        );
      }).toList();
    }

    return await remoteDataSource.updateCommunity(
      id: id,
      name: name,
      type: type,
      members: memberModels,
    );
  }

  @override
  Future<void> deleteCommunity(String id) async {
    await remoteDataSource.deleteCommunity(id);
  }

  @override
  Future<void> leaveCommunity(String id) async {
    await remoteDataSource.leaveCommunity(id);
  }

  @override
  Future<void> removeCommunityMember(String communityId, String userId) async {
    await remoteDataSource.removeCommunityMember(communityId, userId);
  }
}
