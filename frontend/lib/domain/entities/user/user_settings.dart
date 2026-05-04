class UserSettings {
  final String theme;
  final bool notifications;
  final String language;

  const UserSettings({
    required this.theme,
    required this.notifications,
    required this.language,
  });

  UserSettings copyWith({
    String? theme,
    bool? notifications,
    String? language,
  }) {
    return UserSettings(
      theme: theme ?? this.theme,
      notifications: notifications ?? this.notifications,
      language: language ?? this.language,
    );
  }

  @override
  String toString() =>
      'UserSettings(theme: $theme, notifications: $notifications, language: $language)';
}
