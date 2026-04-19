import '../task/task_model.dart';
import '../reservation/reservation_model.dart';

class DailyProgramSummary {
  final int taskSayisi;
  final int etkinlikSayisi;

  DailyProgramSummary({this.taskSayisi = 0, this.etkinlikSayisi = 0});

  factory DailyProgramSummary.fromJson(Map<String, dynamic> json) {
    return DailyProgramSummary(
      taskSayisi: json['task_sayisi'] ?? 0,
      etkinlikSayisi: json['etkinlik_sayisi'] ?? 0,
    );
  }
}

class DailyProgramItems {
  final List<TaskModel> tasks;
  final List<ReservationModel> etkinlikler;

  DailyProgramItems({required this.tasks, required this.etkinlikler});

  factory DailyProgramItems.fromJson(Map<String, dynamic> json) {
    return DailyProgramItems(
      tasks: (json['tasks'] as List? ?? [])
          .map((e) => TaskModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      etkinlikler: (json['etkinlikler'] as List? ?? [])
          .map((e) => ReservationModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class DailyProgramModel {
  final String id;
  final DateTime tarih;
  final String kullaniciId;
  final DailyProgramSummary ozet;
  final DailyProgramItems items;

  DailyProgramModel({
    required this.id,
    required this.tarih,
    required this.kullaniciId,
    required this.ozet,
    required this.items,
  });

  factory DailyProgramModel.fromJson(Map<String, dynamic> json) {
    return DailyProgramModel(
      id: json['id'] ?? json['_id'] ?? '',
      tarih: DateTime.parse(json['tarih']),
      kullaniciId: json['kullanici_id'] ?? '',
      ozet: DailyProgramSummary.fromJson(json['ozet'] ?? {}),
      items: DailyProgramItems.fromJson(json['items'] ?? {}),
    );
  }
}
