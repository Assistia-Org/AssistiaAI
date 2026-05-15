class Reservation {
  final String id;
  final String? userId;
  final String? communityId;
  final String? communityName;
  final List<String> assignedTo;
  final String category;
  final String title;
  final Map<String, dynamic> details;
  final bool isShared;
  final DateTime? startDate;
  final DateTime? endDate;
  final String status;

  Reservation({
    this.id = '',
    this.userId,
    this.communityId,
    this.communityName,
    this.assignedTo = const [],
    required this.category,
    required this.title,
    required this.details,
    this.isShared = false,
    this.startDate,
    this.endDate,
    required this.status,
  });
}
