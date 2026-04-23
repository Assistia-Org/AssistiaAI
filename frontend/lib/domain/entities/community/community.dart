import '../user/user.dart';

class CommunityMember {
  final User user;
  final String role;

  CommunityMember({
    required this.user,
    required this.role,
  });
}

class Community {
  final String id;
  final String name;
  final String type;
  final String ownerId;
  final List<CommunityMember> members;

  Community({
    required this.id,
    required this.name,
    required this.type,
    required this.ownerId,
    required this.members,
  });

  bool isOwner(String userId) => ownerId == userId;
}
