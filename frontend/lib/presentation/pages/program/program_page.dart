import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'add_flight_reservation_page.dart';
import 'add_manual_task_page.dart';
import '../../../core/constants/dummy_data.dart';

class ProgramPage extends StatefulWidget {
  const ProgramPage({super.key});

  @override
  State<ProgramPage> createState() => _ProgramPageState();
}

class _ProgramPageState extends State<ProgramPage> {
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
                      minHeight: MediaQuery.of(context).size.height - 0,
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
                        // Title and Action Buttons Row (Fitted to avoid overflow)
                        Padding(
                          padding: const EdgeInsets.only(left: 20, top: 20, right: 15, bottom: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Günlük Program",
                                style: GoogleFonts.inter(
                                  fontSize: 20, // Reduced from 22
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              // Single "Etkinlik Ekle" Button with Popup Menu
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
                        _buildChronologicalTimeline(),
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

  Widget _buildChronologicalTimeline() {
    // 1. Fetch the program for the selected date from our shared library
    final String selectedDateStr = "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";
    final Map<String, dynamic>? currentProgram = DummyData.programs[selectedDateStr];

    if (currentProgram == null) {
      return _buildEmptyState();
    }

    // 2. Process and merge tasks and reservations from the fetched program
    final List<Map<String, dynamic>> allReservations = (currentProgram['items']['etkinlikler'] as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final List<Map<String, dynamic>> allTasks = (currentProgram['items']['tasks'] as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    
    // Sort reservations by start time
    allReservations.sort((a, b) => a['start_date'].compareTo(b['start_date']));
    
    // Identify which tasks are sub-tasks of which reservations
    List<Map<String, dynamic>> rootItems = [];
    Set<int> assignedTaskIndices = {};

    for (var res in allReservations) {
      List<Map<String, dynamic>> subTasks = [];
      for (int i = 0; i < allTasks.length; i++) {
        var task = allTasks[i];
        
        // Robust time comparison
        String tStart = task['start_date'];
        String rStart = res['start_date'];
        String rEnd = res['end_date'] == '00:00' ? '24:00' : res['end_date']; // Midnight fix

        if (tStart.compareTo(rStart) >= 0 && tStart.compareTo(rEnd) <= 0) {
          subTasks.add(task);
          assignedTaskIndices.add(i);
        }
      }
      res['subTasks'] = subTasks;
      rootItems.add(res);
    }

    // Add remaining tasks that are NOT sub-tasks as root items
    for (int i = 0; i < allTasks.length; i++) {
      if (!assignedTaskIndices.contains(i)) {
        rootItems.add({...allTasks[i], 'subTasks': []});
      }
    }

    // Final sort of all root blocks
    rootItems.sort((a, b) => a['start_date'].compareTo(b['start_date']));

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

  Widget _buildTimelineBlock(Map<String, dynamic> event) {
    bool hasSubTasks = event['subTasks'] != null && (event['subTasks'] as List).isNotEmpty;
    List subTasks = event['subTasks'] ?? [];
    
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
                  event['start_date'],
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
                      color: _getEventColor(event['type']),
                      borderRadius: BorderRadius.circular(2),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          _getEventColor(event['type']),
                          _getEventColor(event['type']).withValues(alpha: 0.3)
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  event['end_date'],
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 20), // Bottom margin
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
                    event: event,
                    isMain: true,
                  ),
                  if (hasSubTasks)
                    ...subTasks.map((sub) => Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: _buildSubTaskRow(sub, _getEventColor(event['type'])),
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

  Widget _buildSubTaskRow(Map<String, dynamic> sub, Color parentColor) {
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
                  sub['start_date'],
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: _getEventColor(sub['type']),
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: Container(
                    width: 1.5,
                    decoration: BoxDecoration(
                      color: _getEventColor(sub['type']).withValues(alpha: 0.3),
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
                event: sub,
                isMain: false,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard({
    required Map<String, dynamic> event,
    bool isMain = true,
  }) {
    final String id = event['id'] ?? "";
    final String type = event['type'];
    final String title = event['title'];
    final String subtitle = event['description'] ?? (event['details'] != null ? "${event['category']} - ${event['status']}" : "");
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
                        if (event['description'] != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              event['description'],
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: Colors.black87,
                                height: 1.4,
                              ),
                            ),
                          ),
                        if (event['details'] != null)
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: (event['details'] as Map<String, dynamic>).entries.map((entry) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        entry.key.toUpperCase(),
                                        style: GoogleFonts.inter(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: color.withValues(alpha: 0.7),
                                        ),
                                      ),
                                      Text(
                                        entry.value.toString(),
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        if (event['tags'] != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: (event['tags'] as List).map((tag) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    "#$tag",
                                    style: GoogleFonts.inter(
                                      fontSize: 9,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        if (event['end_date'] != null && !isMain)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                Icon(Icons.access_time_filled_rounded, size: 12, color: color),
                                const SizedBox(width: 4),
                                Text(
                                  "BİTİŞ: ${event['end_date']}",
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (event['priority'] != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Row(
                              children: [
                                Icon(Icons.flag_rounded, size: 12, color: color),
                                const SizedBox(width: 4),
                                Text(
                                  "${event['priority'].toString().toUpperCase()} PRIORITELI",
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                  ),
                                ),
                              ],
                            ),
                          ),
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
