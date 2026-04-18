import 'package:flutter/material.dart';

class DummyData {
  static const String today = '2026-04-18';
  
  static final Map<String, dynamic> programs = {
    '2026-04-18': {
      'tarih': '2026-04-18',
      'kullanici_id': 'user_123',
      'ozet': {'task_sayisi': 3, 'etkinlik_sayisi': 2},
      'items': {
        'tasks': [
          {
            'id': 'task_1',
            'creator_id': 'user_123',
            'assigned_to': ['user_123'],
            'community_id': 'comm_1',
            'type': 'Görev',
            'title': 'Akşam Hazırlığı',
            'description': 'Eşyaların düzenlenmesi ve valiz hazırlığı',
            'start_date': '16:00',
            'end_date': '17:00',
            'priority': 'medium',
            'status': 'completed',
            'tags': ['hazırlık', 'seyahat']
          },
          {
            'id': 'task_2',
            'creator_id': 'user_123',
            'assigned_to': ['user_123'],
            'community_id': 'comm_1',
            'type': 'Toplantı',
            'title': 'Gece Senkronu',
            'description': 'Otel Lobby / Google Meet üzerinden katılım',
            'start_date': '21:30',
            'end_date': '22:15',
            'priority': 'high',
            'status': 'completed',
            'tags': ['iş', 'senkronize']
          },
          {
            'id': 'task_3',
            'creator_id': 'user_123',
            'assigned_to': ['user_123'],
            'community_id': 'comm_1',
            'type': 'Görev',
            'title': 'Rapor İnceleme',
            'description': 'Günün son kontrolleri ve rapor onayı',
            'start_date': '22:45',
            'end_date': '23:30',
            'priority': 'low',
            'status': 'completed',
            'tags': ['rapor', 'kontrol']
          },
        ],
        'etkinlikler': [
          {
            'id': 'res_1',
            'user_id': 'user_123',
            'community_id': 'comm_1',
            'category': 'Uçuş',
            'type': 'Uçuş',
            'title': 'IST - AYT Uçuşu',
            'details': {'gate': 'A12', 'seat': '14B'},
            'is_shared': false,
            'start_date': '09:00',
            'end_date': '11:00',
            'status': 'confirmed' // Not completed
          },
          {
            'id': 'res_2',
            'user_id': 'user_123',
            'community_id': 'comm_1',
            'category': 'Otel',
            'type': 'Otel',
            'title': 'Sea View Resort',
            'details': {'room': '404', 'board': 'All Inclusive'},
            'is_shared': false,
            'start_date': '21:00',
            'end_date': '00:00',
            'status': 'checked-in'
          },
        ]
      }
    },
    '2026-04-19': {
      'tarih': '2026-04-19',
      'kullanici_id': 'user_123',
      'ozet': {'task_sayisi': 2, 'etkinlik_sayisi': 1},
      'items': {
        'tasks': [
          {
            'id': 'task_sun_1',
            'creator_id': 'user_123',
            'assigned_to': ['user_123'],
            'community_id': 'comm_1',
            'type': 'Görev',
            'title': 'Pazar Kahvaltısı',
            'description': 'Sahil restoranında açık büfe brunch seansı',
            'start_date': '10:00',
            'end_date': '12:00',
            'priority': 'low',
            'status': 'pending', 
            'tags': ['keyif', 'brunch']
          },
          {
            'id': 'task_sun_2',
            'creator_id': 'user_123',
            'assigned_to': ['user_123'],
            'community_id': 'comm_1',
            'type': 'Görev',
            'title': 'Sahil Yürüyüşü',
            'description': 'Lara sahil bandında akşamüstü yürüyüşü',
            'start_date': '17:00',
            'end_date': '18:30',
            'priority': 'low',
            'status': 'pending',
            'tags': ['sağlık', 'huzur']
          },
        ],
        'etkinlikler': [
          {
            'id': 'res_sun_1',
            'user_id': 'user_123',
            'community_id': 'comm_1',
            'category': 'Uçuş',
            'type': 'Uçuş',
            'title': 'AYT - IST Uçuşu',
            'details': {'gate': 'C04', 'seat': '02A (Business)'},
            'is_shared': false,
            'start_date': '21:00',
            'end_date': '23:00',
            'status': 'scheduled'
          },
        ]
      }
    }
  };

  static Color getEventColor(String type) {
    switch (type) {
      case 'Uçuş': return const Color(0xFF0EA5E9);
      case 'Otel': return const Color(0xFF1E293B);
      case 'Toplantı': return const Color(0xFF8B5CF6);
      case 'Görev': return const Color(0xFF10B981);
      default: return const Color(0xFF64748B);
    }
  }

  static IconData getEventIcon(String type) {
    switch (type) {
      case 'Uçuş': return Icons.flight_takeoff_rounded;
      case 'Otel': return Icons.hotel_rounded;
      case 'Toplantı': return Icons.video_camera_front_rounded;
      case 'Görev': return Icons.task_alt_rounded;
      default: return Icons.event_note_rounded;
    }
  }
}
