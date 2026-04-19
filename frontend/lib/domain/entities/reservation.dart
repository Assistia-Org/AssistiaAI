class Reservation {
  final String id;
  final String? userId;
  final String? communityId;
  final String category;
  final String title;
  final Map<String, dynamic> details;
  final bool isShared;
  final DateTime? startDate;
  final DateTime? endDate;
  final String status;

  Reservation({
    required this.id,
    this.userId,
    this.communityId,
    required this.category,
    required this.title,
    required this.details,
    this.isShared = false,
    this.startDate,
    this.endDate,
    required this.status,
  });
}
