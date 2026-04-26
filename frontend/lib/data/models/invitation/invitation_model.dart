import '../../../domain/entities/invitation/community_invitation.dart';
import '../community/community_model.dart';
import '../user/user_model.dart';

class InvitationModel extends CommunityInvitation {
  InvitationModel({
    required super.id,
    required super.community,
    required super.inviter,
    required super.inviteeEmail,
    super.invitee,
    required super.status,
    required super.role,
    required super.createdAt,
  });

  factory InvitationModel.fromJson(Map<String, dynamic> json) {
    return InvitationModel(
      id: json['id'] ?? json['_id'],
      community: json['community'] is Map<String, dynamic>
          ? CommunityModel.fromJson(json['community'])
          : json['community'],
      inviter: json['inviter'] is Map<String, dynamic>
          ? UserModel.fromJson(json['inviter'])
          : json['inviter'],
      inviteeEmail: json['invitee_email'],
      invitee: json['invitee'] != null
          ? UserModel.fromJson(json['invitee'])
          : null,
      status: _parseStatus(json['status']),
      role: json['role'] ?? 'member',
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  static InvitationStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return InvitationStatus.pending;
      case 'accepted':
        return InvitationStatus.accepted;
      case 'rejected':
        return InvitationStatus.rejected;
      case 'expired':
        return InvitationStatus.expired;
      default:
        return InvitationStatus.pending;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'community_id': communityId,
      'invitee_email': inviteeEmail,
      'role': role,
      'status': status.name,
    };
  }
}
