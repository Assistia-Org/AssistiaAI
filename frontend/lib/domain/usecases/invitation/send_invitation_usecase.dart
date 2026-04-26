import '../../entities/invitation/community_invitation.dart';
import '../../repositories/invitation/invitation_repository.dart';

class SendInvitationUseCase {
  final InvitationRepository repository;
  SendInvitationUseCase(this.repository);

  Future<CommunityInvitation> call({
    required String communityId,
    required String inviteeEmail,
    String role = 'member',
  }) async {
    return await repository.sendInvitation(
      communityId: communityId,
      inviteeEmail: inviteeEmail,
      role: role,
    );
  }
}
