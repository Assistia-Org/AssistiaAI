import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'add_flight_reservation_page.dart';
import 'add_manual_task_page.dart';
import '../../providers/daily_program_provider.dart';
import '../../../data/models/daily_program_model.dart';
import '../../../data/models/task_model.dart';
import '../../../data/models/reservation_model.dart';
import '../../../core/constants/dummy_data.dart';

class ProgramPage extends ConsumerStatefulWidget {
  const ProgramPage({super.key});

  @override
  ConsumerState<ProgramPage> createState() => _ProgramPageState();
}

class _ProgramPageState extends ConsumerState<ProgramPage> {
  late DateTime _selectedDate;
  late DateTime _firstDayOfCurrentWeek;
  String _monthYearText = "";
  final PageController _pageController = PageController(initialPage: 500); // Large number for "infinite" scroll
  String? _expandedId; // ID of the currently expanded event card

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _firstDayOfCurrentWeek = _getStartOfWeek(DateTime.now());
    _updateMonthYearText(_firstDayOfCurrentWeek);
  }

  DateTime _getStartOfWeek(DateTime date) {
    // Week starts on Monday (1) to Sunday (7)
    int daysToSubtract = date.weekday - 1;
    return DateTime(date.year, date.month, date.day).subtract(Duration(days: daysToSubtract));
  }

  void _updateMonthYearText(DateTime date) {
    final months = [
      '01', '02', '03', '04', '05', '06', 
      '07', '08', '09', '10', '11', '12'
    ];
    setState(() {
      _monthYearText = "${months[date.month - 1]} / ${date.year}";
    });
  }

  void _toggleExpand(String id) {
    setState(() {
      _expandedId = (_expandedId == id ? null : id);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Format selected date for API
    final dateStr = "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";
    final programAsync = ref.watch(dailyProgramByDateProvider(dateStr));

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Top Background Filler (Dark)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 200,
            child: Container(color: const Color(0xFF1B232A)),
          ),
          // Scrollable Content
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            clipBehavior: Clip.none,
            child: Column(
              children: [
                // Header with Dynamic Month/Year and Weekly PageView
                _buildHeaderWithWeeklyDates(),

                // White Body Section with Overlap
                Transform.translate(
                  offset: const Offset(0, -30),
                  child: Container(
                    width: double.infinity,
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height - 200,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title and Action Buttons Row
                        Padding(
                          padding: const EdgeInsets.only(left: 20, top: 20, right: 15, bottom: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Günlük Program",
                                style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              PopupMenuButton<String>(
                                offset: const Offset(0, 45),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                color: const Color(0xFF1B232A),
                                onSelected: (value) => _onEventOptionSelected(value),
                                itemBuilder: (context) => [
                                  _buildPopupMenuItem("Rezerve", Icons.add_location_alt_rounded),
                                  _buildPopupMenuItem("Görev", Icons.add_task_rounded),
                                  _buildPopupMenuItem("Toplantı", Icons.video_camera_front_rounded),
                                ],
                                child: _buildAddEventButton(),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        
                        // Real-time Data Loading
                        programAsync.when(
                          data: (program) => _buildChronologicalTimeline(program),
                          loading: () => const Center(child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 100),
                            child: CircularProgressIndicator(color: Colors.cyanAccent),
                          )),
                          error: (err, stack) => _buildEmptyState(),
                        ),
                        const SizedBox(height: 50),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderWithWeeklyDates() {
    return Container(
      // Further reduced top/bottom padding
      padding: const EdgeInsets.only(top: 30, bottom: 45),
      width: double.infinity,
      color: const Color(0xFF1B232A),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Month / Year Display (Top Right)
          Padding(
            padding: const EdgeInsets.only(right: 30, bottom: 5),
            child: Text(
              _monthYearText,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
                letterSpacing: 1.2,
              ),
            ),
          ),
          // Weekly Date selection PageView
          SizedBox(
            height: 55, // Further reduced to 55 for micro compact look
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                // Calculate month for the first day of the new week
                int weekOffset = index - 500;
                DateTime weekStart = _firstDayOfCurrentWeek.add(Duration(days: weekOffset * 7));
                _updateMonthYearText(weekStart);
              },
              itemBuilder: (context, weekIndex) {
                int weekOffset = weekIndex - 500;
                DateTime weekStart = _firstDayOfCurrentWeek.add(Duration(days: weekOffset * 7));
                
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(7, (dayIndex) {
                      DateTime date = weekStart.add(Duration(days: dayIndex));
                      bool isSelected = date.day == _selectedDate.day && 
                                      date.month == _selectedDate.month && 
                                      date.year == _selectedDate.year;
                      
                      return _buildDateCard(date, isSelected);
                    }),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateCard(DateTime date, bool isSelected) {
    const dayLabels = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    String dayLabel = dayLabels[date.weekday - 1];

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDate = date;
        });
        _updateMonthYearText(date); // Update header when a specific day is clicked
      },
      child: Container(
        width: 48, // Slightly tighter to fit 7 days comfortably
        decoration: BoxDecoration(
          color: isSelected ? Colors.cyanAccent : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              dayLabel,
              style: GoogleFonts.inter(
                fontSize: 10, // Smaller day label
                color: isSelected ? Colors.black87 : Colors.white60,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 2), // Tighter spacing
            Text(
              '${date.day}',
              style: GoogleFonts.inter(
                fontSize: 14, // Micro font for date number
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.black : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddEventButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1B232A),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.add_rounded, color: Colors.cyanAccent, size: 20),
          const SizedBox(width: 6),
          Text(
            "Etkinlik Ekle",
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem(String title, IconData icon) {
    return PopupMenuItem<String>(
      value: title,
      child: Row(
        children: [
          Icon(icon, color: Colors.cyanAccent, size: 20),
          const SizedBox(width: 12),
          Text(
            title,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _onEventOptionSelected(String value) {
    if (value == "Rezerve") {
      _showReservationTypePicker(context);
    } else if (value == "Görev" || value == "Toplantı") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AddManualTaskPage()),
      );
    }
  }

  void _showReservationTypePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: const BoxDecoration(
          color: Color(0xFF1B232A),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(40),
            topRight: Radius.circular(40),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              "Rezervasyon Türü Seçin",
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Eklemek istediğiniz rezervasyon tipini seçerek devam edin.",
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white60,
              ),
            ),
            const SizedBox(height: 32),
            _buildReservationOption(
              context,
              title: "Uçak Rezervasyonu",
              subtitle: "Hızlı ve konforlu uçuş planları",
              icon: Icons.flight_takeoff_rounded,
              color: const Color(0xFF0EA5E9),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddFlightReservationPage()),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildReservationOption(
              context,
              title: "Otel Konaklama",
              subtitle: "Konaklama ve dinlenme detayları",
              icon: Icons.hotel_rounded,
              color: Colors.white,
              iconColor: const Color(0xFF1B232A),
              onTap: () {
                Navigator.pop(context);
                // Action for hotel
              },
            ),
            const SizedBox(height: 16),
            _buildReservationOption(
              context,
              title: "Otobüs Yolculuğu",
              subtitle: "Şehirler arası seyahat planları",
              icon: Icons.directions_bus_rounded,
              color: const Color(0xFFF59E0B),
              onTap: () {
                Navigator.pop(context);
                // Action for bus
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildReservationOption(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    Color iconColor = Colors.white,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white60,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }

  Color _getEventColor(String type) => DummyData.getEventColor(type);
  IconData _getEventIcon(String type) => DummyData.getEventIcon(type);

  String _getTimeFromDateTime(DateTime? dateTime) {
    if (dateTime == null) return "00:00";
    return DateFormat('HH:mm').format(dateTime);
  }

  DateTime? _parseTimeString(String? timeStr) {
    if (timeStr == null || !timeStr.contains(':')) return null;
    try {
      final parts = timeStr.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, hour, minute);
    } catch (_) {
      return null;
    }
  }

  DateTime _getEffectiveDateTime(dynamic data, bool isTask, {bool isEnd = false}) {
    if (isTask) {
      final TaskModel task = data as TaskModel;
      final DateTime? date = isEnd ? task.endDate : task.startDate;
      if (date != null) return date;
      return DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    } else {
      final ReservationModel res = data as ReservationModel;
      final DateTime? dateField = isEnd ? res.endDate : res.startDate;
      if (dateField != null) return dateField;

      // Fallback to details
      final String? timeStr = isEnd 
          ? res.details['arrival_time']?.toString() 
          : res.details['departure_time']?.toString();
      final DateTime? parsed = _parseTimeString(timeStr);
      if (parsed != null) return parsed;

      return DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    }
  }

  Widget _buildChronologicalTimeline(DailyProgramModel program) {
    final List<ReservationModel> allReservations = List.from(program.items.etkinlikler);
    final List<TaskModel> allTasks = List.from(program.items.tasks);
    
    // Sort items by effective start time
    List<Map<String, dynamic>> allItems = [];
    for (var res in allReservations) {
      allItems.add({'data': res, 'isTask': false, 'time': _getEffectiveDateTime(res, false)});
    }
    for (var task in allTasks) {
      allItems.add({'data': task, 'isTask': true, 'time': _getEffectiveDateTime(task, true)});
    }
    
    allItems.sort((a, b) => (a['time'] as DateTime).compareTo(b['time'] as DateTime));
    
    // Group sub-tasks under reservations if they fall within the time window
    List<Map<String, dynamic>> rootItems = [];
    Set<int> assignedItemIndices = {};

    for (int i = 0; i < allItems.length; i++) {
      if (assignedItemIndices.contains(i)) continue;
      final item = allItems[i];
      if (item['isTask']) {
        rootItems.add({...item, 'subTasks': <TaskModel>[]});
        continue;
      }

      // It's a reservation - look for tasks that fall within its window
      final ReservationModel res = item['data'] as ReservationModel;
      final DateTime resStart = item['time'] as DateTime;
      final DateTime resEnd = _getEffectiveDateTime(res, false, isEnd: true);
      
      List<TaskModel> subTasks = [];
      for (int j = 0; j < allItems.length; j++) {
        if (i == j || assignedItemIndices.contains(j)) continue;
        final candidate = allItems[j];
        if (!candidate['isTask']) continue;

        final DateTime taskTime = candidate['time'] as DateTime;
        if (taskTime.isAfter(resStart.subtract(const Duration(seconds: 1))) && 
            taskTime.isBefore(resEnd.add(const Duration(seconds: 1)))) {
          subTasks.add(candidate['data'] as TaskModel);
          assignedItemIndices.add(j);
        }
      }
      rootItems.add({...item, 'subTasks': subTasks});
    }

    if (rootItems.isEmpty) return _buildEmptyState();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      itemCount: rootItems.length,
      itemBuilder: (context, index) {
        return _buildTimelineBlock(rootItems[index]);
      },
    );
  }

  Widget _buildTimelineBlock(Map<String, dynamic> rootItem) {
    final bool isTask = rootItem['isTask'];
    final dynamic data = rootItem['data'];
    final List<TaskModel> subTasks = rootItem['subTasks'];
    
    final String type = isTask ? (data as TaskModel).type : (data as ReservationModel).category;
    final String startTime = _getTimeFromDateTime(_getEffectiveDateTime(data, isTask));
    final String endTime = isTask ? "" : _getTimeFromDateTime(_getEffectiveDateTime(data, false, isEnd: true));

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Unified Left Rail
          SizedBox(
            width: 55,
            child: Column(
              children: [
                Text(
                  startTime,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Container(
                    width: 3,
                    decoration: BoxDecoration(
                      color: _getEventColor(type),
                      borderRadius: BorderRadius.circular(2),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          _getEventColor(type),
                          _getEventColor(type).withValues(alpha: 0.3)
                        ],
                      ),
                    ),
                  ),
                ),
                if (!isTask) ...[
                  const SizedBox(height: 6),
                  Text(
                    endTime,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Content Column
          Expanded(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEventCard(
                    data: data,
                    isTask: isTask,
                    isMain: true,
                  ),
                  if (subTasks.isNotEmpty)
                    ...subTasks.map((sub) => Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: _buildSubTaskRow(sub, _getEventColor(type)),
                    )),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1B232A).withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.calendar_today_outlined,
              size: 48,
              color: const Color(0xFF1B232A).withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Henüz Bir Plan Yok",
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1B232A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Seçtiğiniz tarih için planlanmış bir etkinlik veya görev bulunamadı.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              // Action to add event
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text("Plan Ekle"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B232A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubTaskRow(TaskModel sub, Color parentColor) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sub-task Time and Indented Line
          Container(
            width: 50,
            margin: const EdgeInsets.only(top: 10),
            child: Column(
              children: [
                Text(
                  _getTimeFromDateTime(sub.dueDate),
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: _getEventColor(sub.type),
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: Container(
                    width: 1.5,
                    decoration: BoxDecoration(
                      color: _getEventColor(sub.type).withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Sub-task Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _buildEventCard(
                data: sub,
                isTask: true,
                isMain: false,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard({
    required dynamic data,
    required bool isTask,
    bool isMain = true,
  }) {
    final String id = isTask ? (data as TaskModel).id : (data as ReservationModel).id;
    final String type = isTask ? (data as TaskModel).type : (data as ReservationModel).category;
    final String title = isTask ? (data as TaskModel).title : (data as ReservationModel).title;
    final String subtitle = isTask ? ((data as TaskModel).description ?? "") : ((data as ReservationModel).details['pnr']?.toString() ?? "");
    final Color color = _getEventColor(type);
    final IconData icon = _getEventIcon(type);
    final bool isExpanded = _expandedId == id;

    return GestureDetector(
      onTap: () => _toggleExpand(id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isExpanded ? color.withValues(alpha: 0.5) : (isMain ? Colors.black.withValues(alpha: 0.05) : color.withValues(alpha: 0.15)),
            width: isExpanded ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isExpanded ? color.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.02),
              blurRadius: isExpanded ? 15 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isMain ? type.toUpperCase() : "SÜREÇ DAHİLİNDE",
                            style: GoogleFonts.inter(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: color,
                              letterSpacing: 1,
                            ),
                          ),
                          Icon(
                            isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                            size: 14,
                            color: Colors.grey[400],
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      if (!isExpanded)
                        Text(
                          subtitle,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: Colors.grey[500],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            // Expanded Content
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: isExpanded
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Divider(height: 1),
                        ),
                        if (isTask) ...[
                          if ((data as TaskModel).description != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                (data).description!,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: Colors.black87,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          _buildDetailRow("TİP", data.type, color),
                          if (data.priority != null)
                            _buildDetailRow("ÖNCELİK", data.priority!, color),
                        ] else ...[
                          // Reservation Details
                          _buildDetailRow("PNR", (data as ReservationModel).details['pnr']?.toString() ?? "-", color),
                          _buildDetailRow("KATEGORİ", data.category, color),
                          _buildDetailRow("DURUM", data.status, color),
                        ],
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildDetailRow(String label, String value, Color color) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: color.withValues(alpha: 0.7),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    ),
  );
}

  Widget _buildEnhancedTimelineItem({
    required String type,
    required String startTime,
    required String endTime,
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
    bool isChild = false,
    bool hasSubTasks = false,
    Color? parentColor,
  }) {
    double calculateHeight(String start, String end) {
      try {
        var s = start.split(':');
        var e = end.split(':');
        double diff = (int.parse(e[0]) + int.parse(e[1])/60.0) - 
                      (int.parse(s[0]) + int.parse(s[1])/60.0);
        if (diff < 0) diff += 24; // Handle midnight overlap
        return diff * 60 + 20;
      } catch (_) {
        return 80;
      }
    }

    double lineHeight = calculateHeight(startTime, endTime);

    return Padding(
      padding: EdgeInsets.only(left: isChild ? 45 : 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time Column
          SizedBox(
            width: 55,
            child: Column(
              children: [
                Text(
                  startTime,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                // Indicator Line
                Container(
                  width: 3,
                  height: hasSubTasks ? 120 : (isChild ? 40 : 45),
                  decoration: BoxDecoration(
                    color: isChild ? parentColor?.withValues(alpha: 0.5) : color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  endTime,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Content Card
          Expanded(
            child: Container(
              margin: EdgeInsets.only(bottom: hasSubTasks ? 10 : 20),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: isChild ? color.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.05),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isChild)
                          Text(
                            "SÜREÇ DAHİLİNDE",
                            style: GoogleFonts.inter(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: color,
                              letterSpacing: 1,
                            ),
                          ),
                        Text(
                          title,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: Colors.grey[500],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String time, String title, String subtitle, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 45,
          child: Column(
            children: [
              Text(
                time,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 2,
                height: 60,
                color: Colors.grey[100],
              ),
            ],
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 25),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
