import 'package:flutter/material.dart';

class EventMapper {
  /// Returns the UI color for a given event category or type
  static Color getColor(String type) {
    final t = type.toLowerCase();
    if (t.contains('uçuş') || t == 'flight') return const Color(0xFF0EA5E9); // Sky Blue
    if (t.contains('otel') || t == 'hotel') return const Color(0xFF6366F1); // Indigo
    if (t.contains('otobüs') || t == 'bus') return const Color(0xFFF59E0B); // Amber
    if (t.contains('görev') || t == 'task') return const Color(0xFF10B981); // Emerald
    if (t.contains('toplantı') || t == 'meeting') return const Color(0xFF8B5CF6); // Violet
    if (t.contains('yemek') || t == 'restaurant') return const Color(0xFFEAB308); // Yellow
    if (t.contains('spor') || t == 'fitness') return const Color(0xFFF43F5E); // Rose
    if (t.contains('eğlence') || t == 'fun') return const Color(0xFFEC4899); // Pink
    
    return const Color(0xFF64748B); // Default Slate
  }

  /// Returns the icon for a given event category or type
  static IconData getIcon(String type) {
    final t = type.toLowerCase();
    if (t.contains('uçuş') || t == 'flight') return Icons.flight_takeoff_rounded;
    if (t.contains('otel') || t == 'hotel') return Icons.hotel_rounded;
    if (t.contains('otobüs') || t == 'bus') return Icons.directions_bus_rounded;
    if (t.contains('görev') || t == 'task') return Icons.task_alt_rounded;
    if (t.contains('toplantı') || t == 'meeting') return Icons.video_camera_front_rounded;
    if (t.contains('yemek') || t == 'restaurant') return Icons.restaurant_rounded;
    if (t.contains('spor') || t == 'fitness') return Icons.fitness_center_rounded;
    if (t.contains('eğlence') || t == 'fun') return Icons.celebration_rounded;
    
    return Icons.event_note_rounded;
  }

  /// Returns the display label for the category
  static String getLabel(String type) {
    final t = type.toLowerCase();
    if (t.contains('uçuş') || t == 'flight') return 'UÇUŞ';
    if (t.contains('otel') || t == 'hotel') return 'OTEL';
    if (t.contains('otobüs') || t == 'bus') return 'OTOBÜS';
    if (t.contains('görev') || t == 'task') return 'GÖREV';
    if (t.contains('toplantı') || t == 'meeting') return 'TOPLANTI';
    if (t.contains('yemek') || t == 'restaurant') return 'YEMEK';
    if (t.contains('spor') || t == 'fitness') return 'SPOR';
    if (t.contains('eğlence') || t == 'fun') return 'EĞLENCE';
    
    return type.toUpperCase();
  }

  /// Returns the translated label for task status
  static String getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Bekliyor';
      case 'in_progress':
        return 'İşlemde';
      case 'completed':
        return 'Tamamlandı';
      case 'overdue':
        return 'Geçti';
      case 'confirmed':
        return 'Onaylandı';
      case 'scheduled':
        return 'Planlandı';
      case 'cancelled':
        return 'İptal Edildi';
      default:
        return status.toUpperCase();
    }
  }

  /// Returns the color for task status
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFF64748B); // Slate
      case 'in_progress':
        return const Color(0xFF3B82F6); // Blue
      case 'completed':
        return const Color(0xFF10B981); // Emerald
      case 'overdue':
        return const Color(0xFFF43F5E); // Rose
      default:
        return const Color(0xFF94A3B8); // Default
    }
  }
}
