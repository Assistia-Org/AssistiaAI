import '../../../domain/entities/user/user.dart';
import '../../../domain/entities/user/user_settings.dart';

class UserModel extends User {
  UserModel({
    required super.id,
    required super.username,
    required super.email,
    required super.displayName,
    super.avatarUrl,
    super.personalSettings,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    UserSettings? settings;
    final raw = json['personal_settings'];
    if (raw != null && raw is Map<String, dynamic>) {
      settings = UserSettings(
        theme: (raw['theme'] as String?) ?? 'light',
        notifications: (raw['notifications'] as bool?) ?? true,
        language: (raw['language'] as String?) ?? 'tr',
      );
    }
    return UserModel(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      displayName: json['display_name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      personalSettings: settings,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      if (personalSettings != null)
        'personal_settings': {
          'theme': personalSettings!.theme,
          'notifications': personalSettings!.notifications,
          'language': personalSettings!.language,
        },
    };
  }
}
