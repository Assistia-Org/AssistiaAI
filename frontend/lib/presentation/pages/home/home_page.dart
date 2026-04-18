import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/dummy_data.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late List<Map<String, dynamic>> _localTasks;
  late List<Map<String, dynamic>> _localReservations;

  @override
  void initState() {
    super.initState();
    // Initialize local state from DummyData
    final Map<String, dynamic>? todayProgram = DummyData.programs[DummyData.today];
    _localTasks = todayProgram != null 
        ? List<Map<String, dynamic>>.from(todayProgram['items']['tasks']) 
        : [];
    _localReservations = todayProgram != null 
        ? List<Map<String, dynamic>>.from(todayProgram['items']['etkinlikler']) 
        : [];
  }

  void _completeTask(String taskId) {
    setState(() {
      final index = _localTasks.indexWhere((t) => t['id'] == taskId);
      if (index != -1) {
        _localTasks[index]['status'] = 'completed';
      }
    });
    Navigator.pop(context); // Close bottom sheet
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Görev başarıyla tamamlandı!', style: GoogleFonts.inter()),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showTaskActions(Map<String, dynamic> task) {
    final String calculatedStatus = DummyData.getCalculatedStatus(task);
    final Color themeColor = DummyData.getEventColor(task['type']);

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
                  child: Icon(DummyData.getEventIcon(task['type']), color: themeColor),
                ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task['type'].toString().toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: themeColor,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      '${task['start_date']} - ${task['end_date']}',
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
                    color: calculatedStatus == 'TAMAMLANDI' 
                      ? const Color(0xFF10B981).withValues(alpha: 0.1)
                      : (calculatedStatus == 'İŞLEMDE' ? Colors.blue.withValues(alpha: 0.1) : Colors.grey[100]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    calculatedStatus,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: calculatedStatus == 'TAMAMLANDI' 
                        ? const Color(0xFF065F46)
                        : (calculatedStatus == 'İŞLEMDE' ? Colors.blue[700] : Colors.grey[600]),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 25),
            Text(
              task['title'],
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1B232A),
              ),
            ),
            const SizedBox(height: 12),
            
            // Structured Details for Reservations or Simple Description for Tasks
            if (task['details'] != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: (task['details'] as Map<String, dynamic>).entries.map((entry) {
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
                task['description'] ?? 'Detaylı açıklama bulunmuyor.',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
            
            const SizedBox(height: 40),
            
            // Action Buttons
            if (calculatedStatus != 'TAMAMLANDI')
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: calculatedStatus == 'BEKLİYOR' ? null : () => _completeTask(task['id']),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    disabledBackgroundColor: Colors.grey[200],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    elevation: 0,
                  ),
                  child: Text(
                    calculatedStatus == 'BEKLİYOR' ? 'Saati Bekleniyor...' : 'Görevi Tamamla',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: calculatedStatus == 'BEKLİYOR' ? Colors.grey[400] : Colors.white,
                    ),
                  ),
                ),
              ),
              
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
    // 3. Calculate completion flags for summary ticks
    final bool allTasksDone = _localTasks.isNotEmpty && _localTasks.every((t) => t['status'] == 'completed');
    final bool allReservationsDone = _localReservations.isNotEmpty && _localReservations.every((r) => r['status'] == 'completed');

    // Global Background Color (Darker for Contrast)
    const Color globalBg = Color(0xFFEAEFF5);

    return Scaffold(
      backgroundColor: globalBg,
      body: Stack(
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
                _buildHeader(),
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
                            "Can'a Merhaba",
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
                        _buildReservationsList(_localReservations),

                        const SizedBox(height: 35),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 25),
                          child: _buildSectionHeader("Görevlerim"),
                        ),
                        const SizedBox(height: 15),
                        _buildTasksList(_localTasks),

                        const SizedBox(height: 35),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 25),
                          child: _buildSectionHeader("Toplantılarım"),
                        ),
                        const SizedBox(height: 15),
                        _buildMeetingsList(_localTasks),

                        const SizedBox(height: 60),
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

  Widget _buildHeader() {
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
                'Bugün için her şey hazır görünüyor!',
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

  Widget _buildReservationsList(List<Map<String, dynamic>> items) {
    if (items.isEmpty) return const Padding(padding: EdgeInsets.symmetric(horizontal: 25), child: Text("Yakınlarda rezervasyon yok"));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      clipBehavior: Clip.none,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Row(
          children: items.map((res) {
            final isFlight = res['type'] == 'Uçuş';
            final String calculatedStatus = DummyData.getCalculatedStatus(res);
            return Padding(
              padding: const EdgeInsets.only(right: 15),
              child: GestureDetector(
                onTap: () => _showTaskActions(res),
                child: _buildInfoCard(
                  type: res['type'],
                  title: res['title'],
                  subtitle: isFlight ? "Koltuk: ${res['details']['seat']}" : "Oda: ${res['details']['room']}",
                  status: calculatedStatus,
                  time: res['start_date'],
                  icon: DummyData.getEventIcon(res['type']),
                  color: DummyData.getEventColor(res['type']),
                  isCompleted: calculatedStatus == 'TAMAMLANDI',
                  isInProgress: calculatedStatus == 'İŞLEMDE',
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTasksList(List<Map<String, dynamic>> items) {
    final taskItems = items.where((i) => i['type'] == 'Görev').toList();
    if (taskItems.isEmpty) return const Padding(padding: EdgeInsets.symmetric(horizontal: 25), child: Text("Bugün için görev yok"));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      clipBehavior: Clip.none,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Row(
          children: taskItems.map((task) {
            final String calculatedStatus = DummyData.getCalculatedStatus(task);
            return Padding(
              padding: const EdgeInsets.only(right: 15),
              child: GestureDetector(
                onTap: () => _showTaskActions(task),
                child: _buildInfoCard(
                  type: "Görev",
                  title: task['title'],
                  subtitle: "Öncelik: ${task['priority'].toString().toUpperCase()}",
                  status: calculatedStatus,
                  time: task['start_date'],
                  icon: DummyData.getEventIcon(task['type']),
                  color: DummyData.getEventColor(task['type']),
                  isCompleted: calculatedStatus == 'TAMAMLANDI',
                  isInProgress: calculatedStatus == 'İŞLEMDE',
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMeetingsList(List<Map<String, dynamic>> items) {
    final meetingItems = items.where((i) => i['type'] == 'Toplantı').toList();
    if (meetingItems.isEmpty) return const Padding(padding: EdgeInsets.symmetric(horizontal: 25), child: Text("Bugün toplantı yok"));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      clipBehavior: Clip.none,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Row(
          children: meetingItems.map((meeting) {
            final String calculatedStatus = DummyData.getCalculatedStatus(meeting);
            return Padding(
              padding: const EdgeInsets.only(right: 15),
              child: GestureDetector(
                onTap: () => _showTaskActions(meeting),
                child: _buildInfoCard(
                  type: "Online Toplantı",
                  title: meeting['title'],
                  subtitle: "Platform: Google Meet",
                  status: calculatedStatus,
                  time: meeting['start_date'],
                  icon: DummyData.getEventIcon(meeting['type']),
                  color: DummyData.getEventColor(meeting['type']),
                  isCompleted: calculatedStatus == 'TAMAMLANDI',
                  isInProgress: calculatedStatus == 'İŞLEMDE',
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
