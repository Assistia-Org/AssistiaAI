import '../../../domain/entities/reservation/reservation.dart';

class ReservationModel extends Reservation {
  ReservationModel({
    required super.id,
    super.userId,
    super.communityId,
    super.communityName,
    super.assignedTo,
    required super.category,
    required super.title,
    required super.details,
    super.isShared,
    super.startDate,
    super.endDate,
    required super.status,
  });

  factory ReservationModel.fromJson(Map<String, dynamic> json) {
    return ReservationModel(
      id: json['id'] ?? json['_id'],
      userId: json['user_id'],
      communityId: json['community_id'],
      communityName: json['community_name'],
      assignedTo: List<String>.from(json['assigned_to'] ?? []),
      category: json['category'],
      title: json['title'],
      details: json['details'] ?? {},
      isShared: json['is_shared'] ?? false,
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'])
          : null,
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'])
          : null,
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'community_id': communityId,
      'community_name': communityName,
      'assigned_to': assignedTo,
      'category': category,
      'title': title,
      'details': details,
      'is_shared': isShared,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'status': status,
    };
  }

  factory ReservationModel.fromEntity(Reservation entity) {
    return ReservationModel(
      id: entity.id,
      userId: entity.userId,
      communityId: entity.communityId,
      communityName: entity.communityName,
      assignedTo: entity.assignedTo,
      category: entity.category,
      title: entity.title,
      details: entity.details,
      isShared: entity.isShared,
      startDate: entity.startDate,
      endDate: entity.endDate,
      status: entity.status,
    );
  }
}
