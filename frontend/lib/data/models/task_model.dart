class TaskModel {
  final String id;
  final String creatorId;
  final List<String> assignedTo;
  final String? communityId;
  final String type;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final DateTime? startDate; 
  final DateTime? endDate;   
  final String priority;
  final String status;
  final List<String> tags;

  TaskModel({
    required this.id,
    required this.creatorId,
    required this.assignedTo,
    this.communityId,
    required this.type,
    required this.title,
    this.description,
    this.dueDate,
    this.startDate,
    this.endDate,
    this.priority = 'medium',
    this.status = 'pending',
    this.tags = const [],
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] ?? json['_id'] ?? '',
      creatorId: json['creator_id'] ?? '',
      assignedTo: List<String>.from(json['assigned_to'] ?? []),
      communityId: json['community_id'],
      type: json['type'] ?? 'Görev',
      title: json['title'] ?? '',
      description: json['description'],
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date']) : null,
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      priority: json['priority'] ?? 'medium',
      status: json['status'] ?? 'pending',
      tags: List<String>.from(json['tags'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'creator_id': creatorId,
      'assigned_to': assignedTo,
      'community_id': communityId,
      'type': type,
      'title': title,
      'description': description,
      'due_date': dueDate?.toIso8601String(),
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'priority': priority,
      'status': status,
      'tags': tags,
    };
  }
}
