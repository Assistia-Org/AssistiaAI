import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/event_mapper.dart';
import '../../../data/models/reservation/reservation_model.dart';
import '../../../data/models/task/task_model.dart';
import '../../providers/task_provider.dart';
import '../../providers/daily_program_provider.dart';

class CategoryListingPage extends ConsumerStatefulWidget {
  final String title;
  final List<TaskModel>? tasks;
  final List<ReservationModel>? reservations;

  const CategoryListingPage({
    super.key,
    required this.title,
    this.tasks,
    this.reservations,
  });

  @override
  ConsumerState<CategoryListingPage> createState() => _CategoryListingPageState();
}

class _CategoryListingPageState extends ConsumerState<CategoryListingPage> {
  String? _expandedId;

  void _toggleExpand(String id) {
    setState(() {
      _expandedId = (_expandedId == id) ? null : id;
    });
  }

  Future<void> _completeTask(String taskId) async {
    try {
      await ref.read(taskControllerProvider).updateTaskStatus(taskId, 'completed');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Görev başarıyla tamamlandı!', style: GoogleFonts.inter()),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.invalidate(dailyProgramByDateProvider(DateFormat('yyyy-MM-dd').format(DateTime.now())));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    }
  }

  Future<void> _deleteTask(String taskId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Silme Onayı', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text('Bu öğeyi kalıcı olarak silmek istediğinize emin misiniz?', style: GoogleFonts.inter()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(taskControllerProvider).deleteTask(taskId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Öğe silindi')));
          ref.invalidate(dailyProgramByDateProvider(DateFormat('yyyy-MM-dd').format(DateTime.now())));
          Navigator.pop(context); // Go back as the list might be outdated
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          widget.title,
          style: GoogleFonts.inter(color: const Color(0xFF111827), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF111827), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (widget.tasks != null && widget.tasks!.isNotEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: widget.tasks!.length,
        itemBuilder: (context, index) => _buildTaskCard(widget.tasks![index]),
      );
    }

    if (widget.reservations != null && widget.reservations!.isNotEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: widget.reservations!.length,
        itemBuilder: (context, index) => _buildReservationCard(widget.reservations![index]),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text("Henüz bir kayıt bulunmuyor", style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildTaskCard(TaskModel task) {
    final bool isExpanded = _expandedId == task.id;
    final color = EventMapper.getColor(task.type);
    final bool isCompleted = task.status == 'completed';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isExpanded ? 0.08 : 0.03),
            blurRadius: isExpanded ? 30 : 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            InkWell(
              onTap: () => _toggleExpand(task.id),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(EventMapper.getIcon(task.type), color: color, size: 26),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: const Color(0xFF111827),
                              decoration: isCompleted ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('HH:mm').format(task.startDate ?? DateTime.now()),
                            style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[500], fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      color: Colors.grey[400],
                    ),
                  ],
                ),
              ),
            ),
            if (isExpanded) _buildTaskDetailSection(task),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskDetailSection(TaskModel task) {
    final bool isCompleted = task.status == 'completed';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          const SizedBox(height: 20),
          _detailRow(Icons.priority_high_rounded, "Öncelik", task.priority.toUpperCase()),
          const SizedBox(height: 12),
          _detailRow(Icons.calendar_month_rounded, "Tarih", DateFormat('dd MMMM yyyy').format(task.startDate ?? DateTime.now())),
          const SizedBox(height: 12),
          if (task.description != null && task.description!.isNotEmpty) ...[
            Text("Açıklama", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[400])),
            const SizedBox(height: 6),
            Text(task.description!, style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF4B5563), height: 1.5)),
            const SizedBox(height: 24),
          ],
          Row(
            children: [
              if (!isCompleted)
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _completeTask(task.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text("Tamamla", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              if (!isCompleted) const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _deleteTask(task.id),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFEF4444)),
                    foregroundColor: const Color(0xFFEF4444),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text("Sil", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReservationCard(ReservationModel res) {
    final bool isExpanded = _expandedId == res.id;
    final color = EventMapper.getColor(res.category);
    final bool isCompleted = res.status == 'completed' || (res.endDate != null && DateTime.now().isAfter(res.endDate!));

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isExpanded ? 0.08 : 0.03),
            blurRadius: isExpanded ? 30 : 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            InkWell(
              onTap: () => _toggleExpand(res.id),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(EventMapper.getIcon(res.category), color: color, size: 26),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            res.title,
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF111827)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            res.category,
                            style: GoogleFonts.inter(fontSize: 12, color: color, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    if (isCompleted)
                      const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20)
                    else
                      Icon(isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: Colors.grey[400]),
                  ],
                ),
              ),
            ),
            if (isExpanded) _buildReservationDetailSection(res),
          ],
        ),
      ),
    );
  }

  Widget _buildReservationDetailSection(ReservationModel res) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          const SizedBox(height: 20),
          _detailRow(Icons.login_rounded, "Başlangıç", _formatDateTime(res.startDate)),
          const SizedBox(height: 12),
          _detailRow(Icons.logout_rounded, "Bitiş", _formatDateTime(res.endDate)),
          const SizedBox(height: 20),
          if (res.details.isNotEmpty) ...[
             Text("Rezervasyon Bilgileri", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[400])),
             const SizedBox(height: 8),
             Wrap(
               spacing: 8,
               runSpacing: 8,
               children: res.details.entries.map((e) => _infoTag(e.key, e.value.toString())).toList(),
             ),
             const SizedBox(height: 24),
          ],
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _deleteTask(res.id), // Same endpoint for removal
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFEF4444)),
                foregroundColor: const Color(0xFFEF4444),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text("Rezervasyonu Sil", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[400]),
        const SizedBox(width: 8),
        Text("$label:", style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600])),
        const SizedBox(width: 6),
        Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF374151))),
      ],
    );
  }

  Widget _infoTag(String key, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(8)),
      child: Text("$key: $value", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF4B5563))),
    );
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return "Belirtilmedi";
    return DateFormat('dd MMM yyyy, HH:mm').format(dt);
  }
}
