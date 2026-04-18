class User {
  final String id;
  final String username;
  final String email;
  final String displayName;
  final String? avatarUrl;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.displayName,
    this.avatarUrl,
  });
}
