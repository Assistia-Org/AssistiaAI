import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/event_mapper.dart';
import '../../providers/daily_program_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/auth_provider.dart';
import '../../../data/models/task/task_model.dart';
import '../../../data/models/reservation/reservation_model.dart';
import '../../../data/models/daily_program/daily_program_model.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  // Local state to track optimizations or UI tweaks if needed
  String _getTodayStr() => DateFormat('yyyy-MM-dd').format(DateTime.now());
  
  String _formatTime(DateTime? dt) {
    if (dt == null) return '--:--';
    return DateFormat('HH:mm').format(dt);
  }

  Future<void> _completeTask(String taskId) async {
    try {
      await ref.read(taskControllerProvider).updateTaskStatus(taskId, 'completed');
      if (mounted) {
        Navigator.pop(context); // Close bottom sheet
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Görev başarıyla tamamlandı!', style: GoogleFonts.inter()),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        // Refresh the program provider
        ref.invalidate(dailyProgramByDateProvider(_getTodayStr()));
      }
    } catch (e) {
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Hata: $e')),
         );
       }
    }
  }

  void _showTaskActions(dynamic item) {
    final bool isTask = item is TaskModel;
    final String type = isTask ? item.type : (item as ReservationModel).category;
    final String status = isTask ? item.status : (item as ReservationModel).status;
    final String displayStatus = EventMapper.getStatusLabel(status).toUpperCase();
    
    final Color themeColor = EventMapper.getColor(type);
    final String title = isTask ? item.title : (item as ReservationModel).title;
    final String description = isTask ? (item.description ?? 'Detaylı açıklama bulunmuyor.') : '';
    final String timeRange = '${_formatTime(item.startDate)} - ${_formatTime(item.endDate)}';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(35),
            topRight: Radius.circular(35),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 30),
            
            // Header: Icon + Type
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(EventMapper.getIcon(type), color: themeColor),
                ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: themeColor,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      timeRange,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Status Badge in Detail
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: status == 'completed' 
                      ? const Color(0xFF10B981).withValues(alpha: 0.1)
                      : (status == 'in_progress' ? Colors.blue.withValues(alpha: 0.1) : Colors.grey[100]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    displayStatus,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: status == 'completed' 
                        ? const Color(0xFF065F46)
                        : (status == 'in_progress' ? Colors.blue[700] : Colors.grey[600]),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 25),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1B232A),
              ),
            ),
            const SizedBox(height: 12),
            
            // Structured Details for Reservations or Simple Description for Tasks
            if (!isTask)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: (item as ReservationModel).details.entries.map((entry) {
                    String label = entry.key == 'seat' ? 'Koltuk' : 
                                   entry.key == 'gate' ? 'Kapı' : 
                                   entry.key == 'room' ? 'Oda No' : 
                                   entry.key == 'board' ? 'Konaklama' : entry.key;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(label, style: GoogleFonts.inter(color: Colors.grey[600], fontWeight: FontWeight.w500)),
                          Text(entry.value.toString(), style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              )
            else
              Text(
                description,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
            
            const SizedBox(height: 40),
            
            // Action Buttons
            if (isTask) ...[
              if (status == 'completed')
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: Color(0xFF10B981), size: 28),
                        SizedBox(width: 10),
                        Text('Bu görev tamamlandı', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                )
              else if (status == 'pending')
                Container(
                  width: double.infinity,
                  height: 60,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(18)),
                  child: Text('Saati Bekleniyor...', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[500])),
                )
              else // in_progress or overdue
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () => _completeTask(item.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      elevation: 0,
                    ),
                    child: Text(
                      'Görevi Tamamla',
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
            ],
              
            const SizedBox(height: 12),
            
            // Delete button (Placeholder as requested)
            SizedBox(
              width: double.infinity,
              height: 60,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Silme özelliği yakında eklenecek.', style: GoogleFonts.inter()))
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.red.withValues(alpha: 0.2)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                child: Text(
                  'Görevi Sil',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[400],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final todayStr = _getTodayStr();
    final programAsync = ref.watch(dailyProgramByDateProvider(todayStr));
    final currentUser = ref.watch(currentUserProvider);
    final String firstName = currentUser?.displayName.split(' ').first ?? 'Kullanıcı';

    // Global Background Color (Darker for Contrast)
    const Color globalBg = Color(0xFFEAEFF5);

    return Scaffold(
      backgroundColor: globalBg,
      body: programAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Hata: $err')),
        data: (program) {
          final tasks = program.items.tasks;
          final reservations = program.items.etkinlikler;
          
          final bool allTasksDone = tasks.isNotEmpty && tasks.every((t) => t.status == 'completed');
          final bool allReservationsDone = reservations.isNotEmpty && reservations.every((r) => r.status == 'completed');
          
          // Dynamic header message
          String headerMsg = 'Bugün için her şey hazır görünüyor!';
          if (tasks.isNotEmpty) {
            final pendingCount = tasks.where((t) => t.status != 'completed').length;
            headerMsg = pendingCount > 0 
                ? 'Bugün tamamlanması gereken $pendingCount görevin var.'
                : 'Harika! Bütün görevlerini tamamladın.';
          }
          
          return Stack(
            children: [
              // Top Background Filler (Dark)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 400,
                child: Container(color: const Color(0xFF1B232A)),
              ),
              // Scrollable Content
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    _buildHeader(headerMsg),
                    Transform.translate(
                      offset: const Offset(0, -30),
                      child: Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: globalBg,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(40),
                            topRight: Radius.circular(40),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 30),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 25),
                              child: Text(
                                "$firstName'a Merhaba",
                                style: GoogleFonts.inter(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            const SizedBox(height: 25),
                            // Daily Summaries Card
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 25),
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(32),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.03),
                                      blurRadius: 40,
                                      offset: const Offset(0, 15),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Günün Özetleri",
                                      style: GoogleFonts.inter(
                                        fontSize: 19,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 25),
                                    _buildDailySummaries(allTasksDone, allReservationsDone),
                                  ],
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 35),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 25),
                              child: _buildSectionHeader("Rezervasyonlarım"),
                            ),
                            const SizedBox(height: 15),
                            _buildReservationsList(reservations),
    
                            const SizedBox(height: 35),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 25),
                              child: _buildSectionHeader("Görevlerim"),
                            ),
                            const SizedBox(height: 15),
                            _buildTasksList(tasks),
    
                            const SizedBox(height: 35),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 25),
                              child: _buildSectionHeader("Toplantılarım"),
                            ),
                            const SizedBox(height: 15),
                            _buildMeetingsList(tasks),
    
                            const SizedBox(height: 60),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      ],
    );
  }

  Widget _buildHeader(String message) {
    return Container(
      padding: const EdgeInsets.only(top: 40, left: 20, right: 20, bottom: 50),
      color: const Color(0xFF1B232A),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF2D3E4E), Color(0xFF1A2A3A)],
              ),
            ),
            child: const Center(
              child: Icon(Icons.auto_awesome, color: Colors.cyanAccent, size: 30),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                message,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailySummaries(bool tasksDone, bool resDone) {
    final List<Map<String, dynamic>> summaries = [
      {'icon': Icons.task_alt_rounded, 'is_done': tasksDone},
      {'icon': Icons.business_center_rounded, 'is_done': resDone},
      {'icon': Icons.insights_rounded, 'is_done': tasksDone && resDone},
      {'icon': Icons.calendar_today_rounded, 'is_gray': true},
      {'icon': Icons.more_horiz_rounded, 'is_last': true},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: summaries.map((s) => _buildSummaryIcon(s)).toList(),
    );
  }

  Widget _buildSummaryIcon(Map<String, dynamic> data) {
    bool isLast = data['is_last'] ?? false;
    bool isGray = data['is_gray'] ?? false;
    bool isDone = data['is_done'] ?? false;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 55,
          height: 55,
          decoration: BoxDecoration(
            gradient: isLast ? null : LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isGray 
                ? [Colors.grey[50]!, Colors.grey[100]!]
                : (isDone 
                    ? [const Color(0xFFE0F2F1), const Color(0xFFB2DFDB)]
                    : [Colors.white, Colors.grey[50]!]),
            ),
            borderRadius: BorderRadius.circular(16),
            border: isLast ? null : Border.all(
              color: isDone ? const Color(0xFF4A9090).withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.05), 
              width: 1.5,
            ),
          ),
          child: Icon(
            data['icon'],
            color: isLast ? Colors.grey[300] : (isDone ? const Color(0xFF4A9090) : Colors.grey[400]),
            size: 22,
          ),
        ),
        if (isDone)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: Color(0xFF4A9090),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, size: 8, color: Colors.white),
            ),
          ),
      ],
    );
  }

  Widget _buildReservationsList(List<ReservationModel> items) {
    if (items.isEmpty) return const Padding(padding: EdgeInsets.symmetric(horizontal: 25), child: Text("Yakınlarda rezervasyon yok", style: TextStyle(color: Colors.grey)));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      clipBehavior: Clip.none,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Row(
          children: items.map((res) {
            final typeLower = res.category.toLowerCase();
            final isFlight = typeLower == 'flight' || typeLower == 'uçuş';
            final statusLabel = EventMapper.getStatusLabel(res.status);
            return Padding(
              padding: const EdgeInsets.only(right: 15),
              child: GestureDetector(
                onTap: () => _showTaskActions(res),
                child: _buildInfoCard(
                  type: EventMapper.getLabel(res.category),
                  title: res.title,
                  subtitle: isFlight ? "Koltuk: ${res.details['seat'] ?? '-'}" : "Oda: ${res.details['room'] ?? '-'}",
                  status: statusLabel,
                  time: _formatTime(res.startDate),
                  icon: EventMapper.getIcon(res.category),
                  color: EventMapper.getColor(res.category),
                  isCompleted: res.status == 'completed',
                  isInProgress: res.status == 'in_progress',
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTasksList(List<TaskModel> items) {
    final taskItems = items.where((i) {
      final t = i.type.toLowerCase();
      return t == 'task' || t == 'görev';
    }).toList();
    
    if (taskItems.isEmpty) return const Padding(padding: EdgeInsets.symmetric(horizontal: 25), child: Text("Bugün için görev yok", style: TextStyle(color: Colors.grey)));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      clipBehavior: Clip.none,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Row(
          children: taskItems.map((task) {
            final statusLabel = EventMapper.getStatusLabel(task.status);
            return Padding(
              padding: const EdgeInsets.only(right: 15),
              child: GestureDetector(
                onTap: () => _showTaskActions(task),
                child: _buildInfoCard(
                  type: "GÖREV",
                  title: task.title,
                  subtitle: "Öncelik: ${task.priority.toString().toUpperCase()}",
                  status: statusLabel,
                  time: _formatTime(task.startDate),
                  icon: EventMapper.getIcon(task.type),
                  color: EventMapper.getColor(task.type),
                  isCompleted: task.status == 'completed',
                  isInProgress: task.status == 'in_progress',
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMeetingsList(List<TaskModel> items) {
    final meetingItems = items.where((i) {
      final t = i.type.toLowerCase();
      return t == 'meeting' || t == 'toplantı';
    }).toList();
    
    if (meetingItems.isEmpty) return const Padding(padding: EdgeInsets.symmetric(horizontal: 25), child: Text("Bugün toplantı yok", style: TextStyle(color: Colors.grey)));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      clipBehavior: Clip.none,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Row(
          children: meetingItems.map((meeting) {
            final statusLabel = EventMapper.getStatusLabel(meeting.status);
            return Padding(
              padding: const EdgeInsets.only(right: 15),
              child: GestureDetector(
                onTap: () => _showTaskActions(meeting),
                child: _buildInfoCard(
                  type: "TOPLANTI",
                  title: meeting.title,
                  subtitle: meeting.description ?? "Detay bulunmuyor",
                  status: statusLabel,
                  time: _formatTime(meeting.startDate),
                  icon: EventMapper.getIcon(meeting.type),
                  color: EventMapper.getColor(meeting.type),
                  isCompleted: meeting.status == 'completed',
                  isInProgress: meeting.status == 'in_progress',
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String type,
    required String title,
    required String subtitle,
    required String status,
    required String time,
    required IconData icon,
    required Color color,
    required bool isCompleted,
    bool isInProgress = false,
  }) {
    return Container(
      width: 230,
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: isInProgress ? color.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.06),
            blurRadius: isInProgress ? 25 : 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Vibrant Color + Icon + Time
          Container(
            height: 90,
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, color.withValues(alpha: 0.85)],
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(icon, color: Colors.white, size: 32),
                ),
                // Integrated Time (High Contrast)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time_filled_rounded, size: 12, color: Colors.white),
                        const SizedBox(width: 5),
                        Text(
                          time,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // White Area: Title, Subtitle, Status
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        type.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: color,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    // Proportional Status Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isCompleted 
                          ? const Color(0xFF10B981).withValues(alpha: 0.1) 
                          : (isInProgress ? Colors.blue.withValues(alpha: 0.1) : Colors.grey[100]),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status,
                        style: GoogleFonts.inter(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: isCompleted 
                            ? const Color(0xFF065F46) 
                            : (isInProgress ? Colors.blue[700] : Colors.grey[500]),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1B232A),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
