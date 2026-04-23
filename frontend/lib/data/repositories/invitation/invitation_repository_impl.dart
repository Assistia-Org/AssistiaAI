import '../../../domain/entities/invitation/community_invitation.dart';
import '../../../domain/repositories/invitation/invitation_repository.dart';
import '../../datasources/invitation/invitation_remote_data_source.dart';

class InvitationRepositoryImpl implements InvitationRepository {
  final InvitationRemoteDataSource remoteDataSource;

  InvitationRepositoryImpl({required this.remoteDataSource});

  @override
  Future<CommunityInvitation> sendInvitation({
    required String communityId,
    required String inviteeEmail,
    String role = 'member',
  }) async {
    return await remoteDataSource.sendInvitation(
      communityId: communityId,
      inviteeEmail: inviteeEmail,
      role: role,
    );
  }

  @override
  Future<List<CommunityInvitation>> getMyInvitations() async {
    return await remoteDataSource.getMyInvitations();
  }

  @override
  Future<CommunityInvitation> acceptInvitation(String invitationId) async {
    return await remoteDataSource.acceptInvitation(invitationId);
  }

  @override
  Future<CommunityInvitation> rejectInvitation(String invitationId) async {
    return await remoteDataSource.rejectInvitation(invitationId);
  }
}
