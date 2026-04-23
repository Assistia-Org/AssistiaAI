import '../../entities/invitation/community_invitation.dart';
import '../../repositories/invitation/invitation_repository.dart';

class RejectInvitationUseCase {
  final InvitationRepository repository;
  RejectInvitationUseCase(this.repository);

  Future<CommunityInvitation> call(String invitationId) async {
    return await repository.rejectInvitation(invitationId);
  }
}
