class TaskModel {
  final String id;
  final String creatorId;
  final List<String> assignedTo;
  final String? communityId;
  final String type;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final String? startDate; // For UI time e.g. "16:00"
  final String? endDate;   // For UI time e.g. "17:00"
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
      startDate: json['start_date'],
      endDate: json['end_date'],
      priority: json['priority'] ?? 'medium',
      status: json['status'] ?? 'pending',
      tags: List<String>.from(json['tags'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    // Helper to combine date and "HH:mm" time into ISO string
    String? combineDateTime(DateTime? date, String? time) {
      if (date == null || time == null || !time.contains(':')) return null;
      try {
        final parts = time.split(':');
        final dt = DateTime(date.year, date.month, date.day, int.parse(parts[0]), int.parse(parts[1]));
        return dt.toIso8601String();
      } catch (_) {
        return null;
      }
    }

    return {
      'id': id,
      'creator_id': creatorId,
      'assigned_to': assignedTo,
      'community_id': communityId,
      'type': type,
      'title': title,
      'description': description,
      'due_date': dueDate?.toIso8601String(),
      'start_date': combineDateTime(dueDate, startDate),
      'end_date': combineDateTime(dueDate, endDate),
      'priority': priority,
      'status': status,
      'tags': tags,
    };
  }
}
