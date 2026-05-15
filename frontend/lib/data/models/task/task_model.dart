class TaskModel {
  final String id;
  final String creatorId;
  final List<String> assignedTo;
  final String? communityId;
  final String? communityName;
  final String type;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final DateTime? startDate;
  final DateTime? endDate;
  final String priority;
  final String status;
  final List<String> tags;
  final String? locationAddress;
  final double? locationLat;
  final double? locationLng;

  TaskModel({
    this.id = '',
    required this.creatorId,
    required this.assignedTo,
    this.communityId,
    this.communityName,
    required this.type,
    required this.title,
    this.description,
    this.dueDate,
    this.startDate,
    this.endDate,
    this.priority = 'medium',
    this.status = 'pending',
    this.tags = const [],
    this.locationAddress,
    this.locationLat,
    this.locationLng,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] ?? json['_id'] ?? '',
      creatorId: json['creator_id'] ?? '',
      assignedTo: List<String>.from(json['assigned_to'] ?? []),
      communityId: json['community_id'],
      communityName: json['community_name'],
      type: json['type'] ?? 'Görev',
      title: json['title'] ?? '',
      description: json['description'],
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'])
          : null,
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'])
          : null,
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'])
          : null,
      priority: json['priority'] ?? 'medium',
      status: json['status'] ?? 'pending',
      tags: List<String>.from(json['tags'] ?? []),
      locationAddress: json['location_address'],
      locationLat: (json['location_lat'] as num?)?.toDouble(),
      locationLng: (json['location_lng'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'creator_id': creatorId,
      'assigned_to': assignedTo,
      'community_id': communityId,
      'community_name': communityName,
      'type': type,
      'title': title,
      'description': description,
      'due_date': dueDate?.toIso8601String(),
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'priority': priority,
      'status': status,
      'tags': tags,
      'location_address': locationAddress,
      'location_lat': locationLat,
      'location_lng': locationLng,
    };
  }

  TaskModel copyWith({
    String? id,
    String? creatorId,
    List<String>? assignedTo,
    String? communityId,
    String? communityName,
    String? type,
    String? title,
    String? description,
    DateTime? dueDate,
    DateTime? startDate,
    DateTime? endDate,
    String? priority,
    String? status,
    List<String>? tags,
    String? locationAddress,
    double? locationLat,
    double? locationLng,
  }) {
    return TaskModel(
      id: id ?? this.id,
      creatorId: creatorId ?? this.creatorId,
      assignedTo: assignedTo ?? this.assignedTo,
      communityId: communityId ?? this.communityId,
      communityName: communityName ?? this.communityName,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      tags: tags ?? this.tags,
      locationAddress: locationAddress ?? this.locationAddress,
      locationLat: locationLat ?? this.locationLat,
      locationLng: locationLng ?? this.locationLng,
    );
  }
}
