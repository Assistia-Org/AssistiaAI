import '../community/community.dart';
import '../user/user.dart';

enum InvitationStatus {
  pending,
  accepted,
  rejected,
  expired
}

class CommunityInvitation {
  final String id;
  final dynamic community; // Can be Community object or String ID
  final dynamic inviter;   // Can be User object or String ID
  final String inviteeEmail;
  final User? invitee;
  final InvitationStatus status;
  final String role;
  final DateTime createdAt;

  CommunityInvitation({
    required this.id,
    required this.community,
    required this.inviter,
    required this.inviteeEmail,
    this.invitee,
    required this.status,
    required this.role,
    required this.createdAt,
  });

  Community? get communityEntity => community is Community ? community : null;
  String get communityId => community is Community ? (community as Community).id : community.toString();
  
  User? get inviterEntity => inviter is User ? inviter : null;
  String get inviterId => inviter is User ? (inviter as User).id : inviter.toString();
}
