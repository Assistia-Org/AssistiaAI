import '../../entities/invitation/community_invitation.dart';

abstract class InvitationRepository {
  Future<CommunityInvitation> sendInvitation({
    required String communityId,
    required String inviteeEmail,
    String role,
  });

  Future<List<CommunityInvitation>> getMyInvitations();

  Future<CommunityInvitation> acceptInvitation(String invitationId);

  Future<CommunityInvitation> rejectInvitation(String invitationId);
}
