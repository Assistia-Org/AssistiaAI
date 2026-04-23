import '../../entities/invitation/community_invitation.dart';
import '../../repositories/invitation/invitation_repository.dart';

class GetMyInvitationsUseCase {
  final InvitationRepository repository;
  GetMyInvitationsUseCase(this.repository);

  Future<List<CommunityInvitation>> call() async {
    return await repository.getMyInvitations();
  }
}
