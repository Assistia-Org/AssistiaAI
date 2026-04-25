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
import 'category_listing_page.dart';

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

  Future<void> _deleteTask(String taskId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Görevi Sil', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text('Bu görevi silmek istediğinize emin misiniz? Bu işlem geri alınamaz.', style: GoogleFonts.inter()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Vazgeç', style: GoogleFonts.inter(color: Colors.grey[600], fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Sil', style: GoogleFonts.inter(color: const Color(0xFFF43F5E), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(taskControllerProvider).deleteTask(taskId);
        if (mounted) {
          Navigator.pop(context); // Close bottom sheet
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Görev silindi', style: GoogleFonts.inter()),
              backgroundColor: const Color(0xFF1B232A),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
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
  }

  void _navigateToListing(String title, {List<TaskModel>? tasks, List<ReservationModel>? reservations}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryListingPage(
          title: title,
          tasks: tasks,
          reservations: reservations,
        ),
      ),
    );
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
                onPressed: () => _deleteTask(item.id),
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
          
          final regularTasks = tasks.where((t) => t.type.toLowerCase() != 'meeting' && t.type.toLowerCase() != 'toplantı').toList();
          final meetingTasks = tasks.where((t) => t.type.toLowerCase() == 'meeting' || t.type.toLowerCase() == 'toplantı').toList();

          final now = DateTime.now();

          final bool tasksDone = regularTasks.isNotEmpty && regularTasks.every((t) => t.status == 'completed');
          final bool meetingsDone = meetingTasks.isNotEmpty && meetingTasks.every((t) => t.status == 'completed');
          
          // Reservations are done if manually completed OR if end time has passed
          final bool resDone = reservations.isNotEmpty && reservations.every((r) {
            final bool isManuallyDone = r.status == 'completed';
            final bool isTimeOver = r.endDate != null && now.isAfter(r.endDate!);
            return isManuallyDone || isTimeOver;
          });
          
          final bool everythingDone = (tasks.isNotEmpty || reservations.isNotEmpty) && 
                                       tasks.every((t) => t.status == 'completed') && 
                                       reservations.every((r) {
                                         final bool isManuallyDone = r.status == 'completed';
                                         final bool isTimeOver = r.endDate != null && now.isAfter(r.endDate!);
                                         return isManuallyDone || isTimeOver;
                                       });
          
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
                            // ── Greeting ──────────────────────────────────
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 25),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Merhaba, $firstName 👋',
                                    style: GoogleFonts.inter(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF1B232A),
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('d MMMM yyyy').format(DateTime.now()),
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // ── Daily Summaries Card ───────────────────────
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 25),
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [Color(0xFF1B232A), Color(0xFF2D3E4E)],
                                  ),
                                  borderRadius: BorderRadius.circular(28),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF1B232A).withValues(alpha: 0.25),
                                      blurRadius: 30,
                                      offset: const Offset(0, 12),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(22),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(7),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Icon(Icons.bar_chart_rounded, color: Colors.cyanAccent, size: 16),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          'Günün Özeti',
                                          style: GoogleFonts.inter(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    _buildDailySummaries(
                                      tasksDone: tasksDone,
                                      meetingsDone: meetingsDone,
                                      resDone: resDone,
                                      everythingDone: everythingDone,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 32),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 25),
                              child: _buildSectionHeader(
                                'Rezervasyonlarım',
                                icon: Icons.confirmation_num_rounded,
                                onTap: () => _navigateToListing('Rezervasyonlarım', reservations: reservations),
                              ),
                            ),
                            const SizedBox(height: 14),
                            _buildReservationsList(reservations),

                            const SizedBox(height: 32),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 25),
                              child: _buildSectionHeader(
                                'Görevlerim',
                                icon: Icons.task_alt_rounded,
                                onTap: () => _navigateToListing('Görevlerim', tasks: tasks.where((t) => t.type.toLowerCase() != 'meeting' && t.type.toLowerCase() != 'toplantı').toList()),
                              ),
                            ),
                            const SizedBox(height: 14),
                            _buildTasksList(tasks),

                            const SizedBox(height: 32),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 25),
                              child: _buildSectionHeader(
                                'Toplantılarım',
                                icon: Icons.video_camera_front_rounded,
                                onTap: () => _navigateToListing('Toplantılarım', tasks: tasks.where((t) => t.type.toLowerCase() == 'meeting' || t.type.toLowerCase() == 'toplantı').toList()),
                              ),
                            ),
                            const SizedBox(height: 14),
                            _buildMeetingsList(tasks),

                            const SizedBox(height: 70),
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

  Widget _buildSectionHeader(String title, {VoidCallback? onTap, IconData? icon}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B232A).withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 15, color: const Color(0xFF1B232A)),
                ),
                const SizedBox(width: 10),
              ],
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1B232A),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1B232A).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Tümü',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1B232A).withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded, size: 13, color: const Color(0xFF1B232A).withValues(alpha: 0.7)),
              ],
            ),
          ),
        ],
      ),
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

  Widget _buildDailySummaries({
    required bool tasksDone,
    required bool meetingsDone,
    required bool resDone,
    required bool everythingDone,
  }) {
    final List<Map<String, dynamic>> summaries = [
      {'icon': Icons.check_circle_outline_rounded, 'is_done': tasksDone},
      {'icon': Icons.business_center_rounded, 'is_done': meetingsDone},
      {'icon': Icons.auto_graph_rounded, 'is_done': resDone},
      {'icon': Icons.calendar_today_rounded, 'is_done': everythingDone},
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
                    ? [const Color(0xFF10B981).withOpacity(0.1), const Color(0xFF10B981).withOpacity(0.2)]
                    : [Colors.white, Colors.grey[50]!]),
            ),
            borderRadius: BorderRadius.circular(18),
            border: isLast ? null : Border.all(
              color: isDone ? const Color(0xFF10B981).withOpacity(0.3) : Colors.black.withOpacity(0.05), 
              width: 1.5,
            ),
          ),
          child: Icon(
            isDone && data['icon'] == Icons.calendar_today_rounded 
                ? Icons.check_circle_rounded 
                : data['icon'],
            color: isLast ? Colors.grey[300] : (isDone ? const Color(0xFF10B981) : Colors.grey[400]),
            size: 24,
          ),
        ),
        if (isDone)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: Color(0xFF10B981),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, size: 8, color: Colors.white),
            ),
          ),
      ],
    );
  }

  Widget _buildReservationsList(List<ReservationModel> items) {
    if (items.isEmpty) return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: _buildEmptyChip('Yakınlarda rezervasyon yok', Icons.confirmation_num_outlined),
    );

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
                  isCompleted: res.status == 'completed' || (res.endDate != null && DateTime.now().isAfter(res.endDate!)),
                  isInProgress: res.status == 'in_progress' || (res.startDate != null && res.endDate != null && DateTime.now().isAfter(res.startDate!) && DateTime.now().isBefore(res.endDate!)),
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
      return t != 'meeting' && t != 'toplantı';
    }).toList();
    
    if (taskItems.isEmpty) return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: _buildEmptyChip('Bugün için görev yok', Icons.task_outlined),
    );

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
                  type: EventMapper.getLabel(task.type),
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
    
    if (meetingItems.isEmpty) return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: _buildEmptyChip('Bugün toplantı yok', Icons.video_camera_front_outlined),
    );

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

  Widget _buildEmptyChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey[400]),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
    // Status colors
    final Color statusBg = isCompleted
        ? const Color(0xFF10B981).withValues(alpha: 0.12)
        : isInProgress
            ? const Color(0xFF3B82F6).withValues(alpha: 0.12)
            : Colors.grey.withValues(alpha: 0.1);
    final Color statusFg = isCompleted
        ? const Color(0xFF065F46)
        : isInProgress
            ? const Color(0xFF1D4ED8)
            : Colors.grey.shade600;

    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isInProgress
                ? color.withValues(alpha: 0.18)
                : Colors.black.withValues(alpha: 0.07),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
        border: isInProgress
            ? Border.all(color: color.withValues(alpha: 0.3), width: 1.5)
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Coloured top strip with icon ──────────────────
          Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, color.withValues(alpha: 0.75)],
              ),
            ),
            child: Stack(
              children: [
                // Large background icon (watermark)
                Positioned(
                  right: -10,
                  bottom: -10,
                  child: Icon(icon, size: 80, color: Colors.white.withValues(alpha: 0.12)),
                ),
                // Centered icon
                Positioned(
                  top: 18,
                  left: 18,
                  child: Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: Colors.white, size: 20),
                  ),
                ),
                // Time pill
                Positioned(
                  bottom: 12,
                  right: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.schedule_rounded, size: 11, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          time,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Completed overlay
                if (isCompleted)
                  Positioned(
                    top: 10,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, size: 10, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),

          // ── Content area ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type label + Status pill
                Row(
                  children: [
                    Text(
                      type.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: color,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status,
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: statusFg,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isCompleted
                        ? Colors.grey.shade400
                        : const Color(0xFF1B232A),
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    decorationColor: Colors.grey.shade400,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade500,
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
