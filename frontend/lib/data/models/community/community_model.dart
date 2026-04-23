import '../../../domain/entities/community/community.dart';
import '../user/user_model.dart';

class CommunityMemberModel extends CommunityMember {
  CommunityMemberModel({
    required UserModel user,
    required super.role,
  }) : super(user: user);

  factory CommunityMemberModel.fromJson(Map<String, dynamic> json) {
    return CommunityMemberModel(
      user: UserModel.fromJson(json['user']),
      role: json['role'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': (user as UserModel).toJson(),
      'role': role,
    };
  }
}

class CommunityModel extends Community {
  CommunityModel({
    required super.id,
    required super.name,
    required super.type,
    required super.ownerId,
    required List<CommunityMemberModel> super.members,
  });

  factory CommunityModel.fromJson(Map<String, dynamic> json) {
    return CommunityModel(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      ownerId: json['owner_id'] as String,
      members: (json['members'] as List? ?? [])
          .map((m) => CommunityMemberModel.fromJson(m))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'owner_id': ownerId,
      'members': members.map((m) => (m as CommunityMemberModel).toJson()).toList(),
    };
  }
}
