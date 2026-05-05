class AssistantMessageModel {
  final String role;
  final String content;

  AssistantMessageModel({
    required this.role,
    required this.content,
  });

  factory AssistantMessageModel.fromJson(Map<String, dynamic> json) {
    return AssistantMessageModel(
      role: json['role'] ?? 'user',
      content: json['content'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'content': content,
    };
  }
}
