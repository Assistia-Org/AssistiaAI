import '../../entities/invitation/community_invitation.dart';
import '../../repositories/invitation/invitation_repository.dart';

class AcceptInvitationUseCase {
  final InvitationRepository repository;
  AcceptInvitationUseCase(this.repository);

  Future<CommunityInvitation> call(String invitationId) async {
    return await repository.acceptInvitation(invitationId);
  }
}
