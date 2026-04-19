import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/event_mapper.dart';
import '../../../data/models/daily_program/daily_program_model.dart';
import '../../../data/models/reservation/reservation_model.dart';
import '../../../data/models/task/task_model.dart';
import '../../providers/daily_program_provider.dart';
import 'add_manual_task_page.dart';
import 'add_flight_reservation_page.dart';
import 'add_bus_reservation_page.dart';
import 'add_manual_hotel_page.dart';

class ProgramPage extends ConsumerStatefulWidget {
  const ProgramPage({super.key});

  @override
  ConsumerState<ProgramPage> createState() => _ProgramPageState();
}

class _ProgramPageState extends ConsumerState<ProgramPage> {
  late DateTime _selectedDate;
  late DateTime _firstDayOfCurrentWeek;
  String _monthYearText = '';
  final PageController _pageController = PageController(initialPage: 500);
  String? _expandedId;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _firstDayOfCurrentWeek = _getStartOfWeek(DateTime.now());
    _updateMonthYearText(_firstDayOfCurrentWeek);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  DateTime _getStartOfWeek(DateTime date) {
    final int daysToSubtract = date.weekday - 1;
    return DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: daysToSubtract));
  }

  void _updateMonthYearText(DateTime date) {
    setState(() {
      _monthYearText = DateFormat('MM / yyyy').format(date);
    });
  }

  void _toggleExpand(String id) {
    setState(() {
      _expandedId = (_expandedId == id) ? null : id;
    });
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    return DateFormat('HH:mm').format(dt);
  }

  DateTime? _parseTimeFromDetails(Map<String, dynamic> details, bool isEnd) {
    final key = isEnd ? 'arrival_time' : 'departure_time';
    final raw = details[key]?.toString();
    if (raw == null || !raw.contains(':')) return null;
    try {
      final parts = raw.split(':');
      return DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
    } catch (_) {
      return null;
    }
  }

  DateTime _effectiveTime(dynamic data, bool isTask, {bool isEnd = false}) {
    DateTime? dt;
    if (isTask) {
      final task = data as TaskModel;
      dt = isEnd ? task.endDate : task.startDate;
    } else {
      final res = data as ReservationModel;
      dt = isEnd ? res.endDate : res.startDate;
      if (dt == null) {
        dt = _parseTimeFromDetails(res.details, isEnd);
      }
    }

    if (dt == null) {
      return DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    }

    final startOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final endOfDay = startOfDay.add(const Duration(days: 1)); // Next day 00:00

    if (dt.isBefore(startOfDay)) {
      return startOfDay;
    }
    if (dt.isAfter(endOfDay)) {
      return endOfDay;
    }

    return dt;
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final programAsync = ref.watch(dailyProgramByDateProvider(dateStr));

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Dark top area
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 210,
            child: Container(color: const Color(0xFF1B232A)),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildTitleBar(),
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        Expanded(
                          child: programAsync.when(
                            data: (program) =>
                                _buildTimeline(program),
                            loading: () => const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF0EA5E9),
                                strokeWidth: 2,
                              ),
                            ),
                            error: (_, __) => _buildEmptyState(),
                          ),
                        ),
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

  // ─── HEADER ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 24, bottom: 10),
            child: Text(
              _monthYearText,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
                letterSpacing: 1.0,
              ),
            ),
          ),
          SizedBox(
            height: 60,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                final offset = index - 500;
                final weekStart = _firstDayOfCurrentWeek
                    .add(Duration(days: offset * 7));
                _updateMonthYearText(weekStart);
              },
              itemBuilder: (_, weekIndex) {
                final offset = weekIndex - 500;
                final weekStart = _firstDayOfCurrentWeek
                    .add(Duration(days: offset * 7));
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(7, (i) {
                      final date = weekStart.add(Duration(days: i));
                      final isSelected = date.year == _selectedDate.year &&
                          date.month == _selectedDate.month &&
                          date.day == _selectedDate.day;
                      return _buildDayChip(date, isSelected);
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

  Widget _buildDayChip(DateTime date, bool isSelected) {
    const labels = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    return GestureDetector(
      onTap: () {
        setState(() => _selectedDate = date);
        _updateMonthYearText(date);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.cyanAccent
              : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              labels[date.weekday - 1],
              style: GoogleFonts.inter(
                fontSize: 10,
                color:
                    isSelected ? Colors.black87 : Colors.white60,
                fontWeight: isSelected
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${date.day}',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.black : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── TITLE BAR ─────────────────────────────────────────────────────────────

  Widget _buildTitleBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 12, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Günlük Program',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          PopupMenuButton<String>(
            offset: const Offset(0, 48),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            color: const Color(0xFF1B232A),
            onSelected: _onMenuSelected,
            itemBuilder: (_) => [
              _menuItem('Rezerve', Icons.add_location_alt_rounded),
              _menuItem('Görev', Icons.add_task_rounded),
            ],
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFF1B232A),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add_rounded,
                      color: Colors.cyanAccent, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Ekle',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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

  PopupMenuItem<String> _menuItem(String label, IconData icon) {
    return PopupMenuItem<String>(
      value: label,
      child: Row(
        children: [
          Icon(icon, color: Colors.cyanAccent, size: 18),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.inter(
                color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _onMenuSelected(String value) {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    if (value == 'Rezerve') {
      _showReservationPicker();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => AddManualTaskPage(initialDate: _selectedDate)),
      ).then((_) {
        // Re-fetch the program for the selected date after returning
        ref.invalidate(dailyProgramByDateProvider(dateStr));
      });
    }
  }

  // ─── TIMELINE ──────────────────────────────────────────────────────────────

  Widget _buildTimeline(DailyProgramModel program) {
    // Flatten all items with timing metadata
    final List<Map<String, dynamic>> allItems = [];

    for (final res in program.items.etkinlikler) {
      DateTime start = _effectiveTime(res, false);
      DateTime end = _effectiveTime(res, false, isEnd: true);
      if (!end.isAfter(start)) end = start.add(const Duration(hours: 1));
      allItems.add({
        'data': res,
        'isTask': false,
        'start': start,
        'end': end,
      });
    }

    for (final task in program.items.tasks) {
      DateTime start = _effectiveTime(task, true);
      DateTime end = _effectiveTime(task, true, isEnd: true);
      if (!end.isAfter(start)) end = start.add(const Duration(hours: 1));
      allItems.add({
        'data': task,
        'isTask': true,
        'start': start,
        'end': end,
      });
    }

    // Sort: by start time ASC, then by duration DESC (longer = parent)
    allItems.sort((a, b) {
      final cmp = (a['start'] as DateTime)
          .compareTo(b['start'] as DateTime);
      if (cmp != 0) return cmp;
      final aDur = (a['end'] as DateTime)
          .difference(a['start'] as DateTime);
      final bDur = (b['end'] as DateTime)
          .difference(b['start'] as DateTime);
      return bDur.compareTo(aDur); // longer first
    });

    // Greedy grouping
    final List<Map<String, dynamic>> roots = [];
    final Set<int> claimed = {};

    for (int i = 0; i < allItems.length; i++) {
      if (claimed.contains(i)) continue;
      final parent = allItems[i];
      final pEnd = parent['end'] as DateTime;
      final pStart = parent['start'] as DateTime;
      final List<Map<String, dynamic>> children = [];

      for (int j = i + 1; j < allItems.length; j++) {
        if (claimed.contains(j)) continue;
        final child = allItems[j];
        final cStart = child['start'] as DateTime;
        // Child overlaps parent window
        if (cStart.isAfter(
                pStart.subtract(const Duration(seconds: 1))) &&
            cStart.isBefore(pEnd)) {
          children.add(child);
          claimed.add(j);
        }
      }

      roots.add({
        'data': parent['data'],
        'isTask': parent['isTask'],
        'start': pStart,
        'end': pEnd,
        'children': children,
      });
      claimed.add(i);
    }

    if (roots.isEmpty) return _buildEmptyState();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      itemCount: roots.length,
      itemBuilder: (_, i) => _buildBlock(roots[i]),
    );
  }

  // ─── TIMELINE BLOCK ────────────────────────────────────────────────────────

  Widget _buildBlock(Map<String, dynamic> root) {
    final bool isTask = root['isTask'] as bool;
    final dynamic data = root['data'];
    final List<Map<String, dynamic>> children =
        root['children'] as List<Map<String, dynamic>>;

    final String type =
        isTask ? (data as TaskModel).type : (data as ReservationModel).category;
    final Color color = EventMapper.getColor(type);
    final String startTime = _formatTime(root['start'] as DateTime?);
    final String endTime = _formatTime(root['end'] as DateTime?);
    final bool hasChildren = children.isNotEmpty;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Left Rail ──
          SizedBox(
            width: 68,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const SizedBox(height: 14),
                Text(
                  startTime,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Center(
                    child: Container(
                      width: 3,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            color,
                            color.withOpacity(hasChildren ? 1.0 : 0.15),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  endTime,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 14),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // ── Cards ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                _buildEventCard(
                  data: data,
                  isTask: isTask,
                  isSub: false,
                ),
                if (hasChildren)
                  ...children.map((child) {
                    final bool childIsTask = child['isTask'] as bool;
                    final dynamic childData = child['data'];
                    final String childStart =
                        _formatTime(child['start'] as DateTime?);
                    final String childEnd =
                        _formatTime(child['end'] as DateTime?);
                    return _buildChildRow(
                        childData, childIsTask, childStart, childEnd, color);
                  }),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildRow(
    dynamic data,
    bool isTask,
    String startTime,
    String endTime,
    Color parentLineColor,
  ) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sub-rail
          SizedBox(
            width: 58,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const SizedBox(height: 12),
                Text(
                  startTime,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: EventMapper.getColor(isTask
                        ? (data as TaskModel).type
                        : (data as ReservationModel).category),
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: Center(
                    child: Container(
                      width: 2,
                      decoration: BoxDecoration(
                        color: parentLineColor.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  endTime,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: _buildEventCard(
                data: data,
                isTask: isTask,
                isSub: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── EVENT CARD ────────────────────────────────────────────────────────────

  Widget _buildEventCard({
    required dynamic data,
    required bool isTask,
    required bool isSub,
  }) {
    // Resolve fields
    final String id =
        isTask ? (data as TaskModel).id : (data as ReservationModel).id;
    final String type =
        isTask ? (data as TaskModel).type : (data as ReservationModel).category;
    final String title =
        isTask ? (data as TaskModel).title : (data as ReservationModel).title;
    final String subtitle = isTask
        ? ((data as TaskModel).description ?? '')
        : '${(data as ReservationModel).category} - ${(data as ReservationModel).status}';

    final Color color = EventMapper.getColor(type);
    final IconData icon = EventMapper.getIcon(type);
    final String label =
        isSub ? 'SÜREÇ DAHİLİNDE' : EventMapper.getLabel(type);
    final bool isExpanded = _expandedId == id;

    return GestureDetector(
      onTap: () => _toggleExpand(id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isExpanded
                ? color.withOpacity(0.25)
                : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Container
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                // Text area
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: color,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: color, // colored title like photo
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF94A3B8),
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: isExpanded ? null : 1,
                        overflow: isExpanded
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: const Color(0xFFCBD5E1),
                ),
              ],
            ),
            // Expanded detail section
            if (isExpanded) ...[
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 12),
              if (isTask) ...[
                if ((data as TaskModel).description != null &&
                    data.description!.isNotEmpty)
                  _detailRow('AÇIKLAMA', data.description!, color),
                _detailRow('TİP', data.type, color),
                _detailRow('ÖNCELİK', data.priority, color),
                _detailRow('DURUM', data.status, color),
              ] else ...[
                _detailRow(
                    'KATEGORİ', (data as ReservationModel).category, color),
                _detailRow('DURUM', data.status, color),
                if (data.details['pnr'] != null)
                  _detailRow('PNR', data.details['pnr'].toString(), color),
              ],
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.bottomRight,
                child: GestureDetector(
                  onTap: () => _showDetailSheet(
                    context: context,
                    data: data,
                    isTask: isTask,
                    color: color,
                    icon: icon,
                    title: title,
                    label: label,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: color.withOpacity(0.2), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Detaylar',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded,
                            size: 14, color: color),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color.withOpacity(0.6),
              letterSpacing: 0.8,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }

  // ─── DETAIL BOTTOM SHEET ────────────────────────────────────────────────────

  void _showDetailSheet({
    required BuildContext context,
    required dynamic data,
    required bool isTask,
    required Color color,
    required IconData icon,
    required String title,
    required String label,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.88,
        expand: false,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // ── Handle bar
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 0),
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // ── Header Row
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: color,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            title,
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(height: 1, color: const Color(0xFFE2E8F0)),
              // ── Scrollable body
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 36),
                  child: isTask
                      ? _buildTaskDetails(data as TaskModel, color)
                      : _buildReservationDetails(data as ReservationModel, color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskDetails(TaskModel task, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status + Priority chips row
        Row(
          children: [
            _statusChip(task.status, color),
            const SizedBox(width: 8),
            _priorityChip(task.priority),
            const SizedBox(width: 8),
            _infoChip(task.type, Icons.category_outlined, const Color(0xFF64748B)),
          ],
        ),
        // Time section
        if (task.startDate != null || task.endDate != null) ...[
          const SizedBox(height: 16),
          _sectionCard(
            color: color,
            title: 'ZAMANLAMA',
            child: Row(
              children: [
                if (task.startDate != null)
                  Expanded(
                    child: _gridCell(
                      'Başlangıç',
                      DateFormat('dd MMM').format(task.startDate!),
                      sub: DateFormat('HH:mm').format(task.startDate!),
                      color: color,
                    ),
                  ),
                if (task.startDate != null && task.endDate != null)
                  Container(
                    width: 1,
                    height: 40,
                    color: const Color(0xFFE2E8F0),
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                if (task.endDate != null)
                  Expanded(
                    child: _gridCell(
                      'Bitiş',
                      DateFormat('dd MMM').format(task.endDate!),
                      sub: DateFormat('HH:mm').format(task.endDate!),
                      color: color,
                    ),
                  ),
              ],
            ),
          ),
        ],
        // Description
        if (task.description != null && task.description!.isNotEmpty) ...[
          const SizedBox(height: 12),
          _sectionCard(
            color: color,
            title: 'AÇIKLAMA',
            child: Text(
              task.description!,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF334155),
                height: 1.5,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildReservationDetails(ReservationModel res, Color color) {
    final details = res.details;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status chip
        _statusChip(res.status, color),
        // Time range card
        if (res.startDate != null || res.endDate != null) ...[
          const SizedBox(height: 14),
          _sectionCard(
            color: color,
            title: 'TARİH & SAAT',
            child: Row(
              children: [
                if (res.startDate != null)
                  Expanded(
                    child: _gridCell(
                      res.category.toLowerCase().contains('hotel') ||
                              res.category.toLowerCase().contains('otel')
                          ? 'Giriş'
                          : 'Kalkış',
                      DateFormat('dd MMM yy').format(res.startDate!),
                      sub: DateFormat('HH:mm').format(res.startDate!),
                      color: color,
                    ),
                  ),
                if (res.startDate != null && res.endDate != null)
                  Container(
                    width: 1,
                    height: 40,
                    color: const Color(0xFFE2E8F0),
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                if (res.endDate != null)
                  Expanded(
                    child: _gridCell(
                      res.category.toLowerCase().contains('hotel') ||
                              res.category.toLowerCase().contains('otel')
                          ? 'Çıkış'
                          : 'Varış',
                      DateFormat('dd MMM yy').format(res.endDate!),
                      sub: DateFormat('HH:mm').format(res.endDate!),
                      color: color,
                    ),
                  ),
              ],
            ),
          ),
        ],
        // Flight detail card (2-col grid)
        if (details.isNotEmpty) ...[
          const SizedBox(height: 12),
          _sectionCard(
            color: color,
            title: 'DETAYLAR',
            child: Wrap(
              spacing: 0,
              runSpacing: 0,
              children: _buildDetailGridCells(details, color),
            ),
          ),
        ],
      ],
    );
  }

  List<Widget> _buildDetailGridCells(
      Map<String, dynamic> details, Color color) {
    // Keys that should span full width (long text)
    const fullWidthKeys = {'passenger', 'guest_name', 'location'};
    final entries = details.entries
        .where((e) => e.value != null && e.value.toString().isNotEmpty)
        .toList();

    final List<Widget> widgets = [];
    int i = 0;
    while (i < entries.length) {
      final e = entries[i];
      final isFullWidth = fullWidthKeys.contains(e.key);
      if (isFullWidth) {
        if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 2));
        widgets.add(SizedBox(
          width: double.infinity,
          child: _gridCell(
            _formatDetailKey(e.key),
            e.value.toString(),
            color: color,
          ),
        ));
        i++;
      } else {
        // Pair two cells side by side
        final eNext = (i + 1 < entries.length &&
                !fullWidthKeys.contains(entries[i + 1].key))
            ? entries[i + 1]
            : null;
        widgets.add(IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: _gridCell(
                  _formatDetailKey(e.key),
                  e.value.toString(),
                  color: color,
                ),
              ),
              if (eNext != null) ...[
                Container(
                  width: 1,
                  color: const Color(0xFFE2E8F0),
                  margin: const EdgeInsets.symmetric(horizontal: 14),
                ),
                Expanded(
                  child: _gridCell(
                    _formatDetailKey(eNext.key),
                    eNext.value.toString(),
                    color: color,
                  ),
                ),
              ] else
                const Expanded(child: SizedBox()),
            ],
          ),
        ));
        widgets.add(const Divider(height: 1, color: Color(0xFFF1F5F9)));
        i += eNext != null ? 2 : 1;
      }
    }
    return widgets;
  }

  Widget _sectionCard({
    required Color color,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: color.withOpacity(0.6),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _gridCell(String label, String value, {String? sub, required Color color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          if (sub != null)
            Text(
              sub,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
        ],
      ),
    );
  }

  Widget _statusChip(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            status,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _priorityChip(String priority) {
    final Color c = priority == 'high'
        ? const Color(0xFFF43F5E)
        : priority == 'medium'
            ? const Color(0xFFF59E0B)
            : const Color(0xFF10B981);
    final String label = priority == 'high'
        ? 'Yüksek'
        : priority == 'medium'
            ? 'Orta'
            : 'Düşük';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withOpacity(0.25)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
            fontSize: 12, fontWeight: FontWeight.w700, color: c),
      ),
    );
  }

  Widget _infoChip(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            style: GoogleFonts.inter(
                fontSize: 12, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  String _formatDetailKey(String key) {
    const map = {
      'pnr': 'PNR',
      'airline': 'Havayolu',
      'flight_no': 'Uçuş No',
      'departure': 'Kalkış',
      'arrival': 'Varış',
      'date': 'Tarih',
      'departure_time': 'Kalkış',
      'arrival_time': 'Varış',
      'status': 'Durum',
      'passenger': 'Yolcu',
      'hotel_name': 'Otel',
      'location': 'Konum',
      'check_in': 'Giriş',
      'check_out': 'Çıkış',
      'check_in_time': 'Giriş Saati',
      'check_out_time': 'Çıkış Saati',
      'room_type': 'Oda',
      'guest_name': 'Misafir',
      'confirmation_no': 'Onay No',
    };
    return map[key] ??
        key
            .replaceAll('_', ' ')
            .split(' ')
            .map((w) =>
                w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
            .join(' ');
  }

  // ─── EMPTY STATE ───────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.calendar_today_outlined,
                size: 44,
                color: Color(0xFFCBD5E1),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Henüz Bir Plan Yok',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Seçilen tarih için planlanmış etkinlik veya görev bulunamadı.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF94A3B8),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── RESERVATION PICKER ────────────────────────────────────────────────────

  void _showReservationPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
        decoration: const BoxDecoration(
          color: Color(0xFF1B232A),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Rezervasyon Türü',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Eklemek istediğiniz türü seçin.',
              style: GoogleFonts.inter(
                  fontSize: 14, color: Colors.white54),
            ),
            const SizedBox(height: 28),
            _resOption(
              title: 'Uçak Rezervasyonu',
              subtitle: 'Uçuş planları ve bilet bilgileri',
              icon: Icons.flight_takeoff_rounded,
              color: const Color(0xFF0EA5E9),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          const AddFlightReservationPage()),
                );
              },
            ),
            const SizedBox(height: 12),
            _resOption(
              title: 'Otel Konaklama',
              subtitle: 'Konaklama ve reservasyon bilgileri',
              icon: Icons.hotel_rounded,
              color: const Color(0xFF6366F1),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddManualHotelPage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _resOption(
              title: 'Otobüs Yolculuğu',
              subtitle: 'Şehirler arası seyahat planı',
              icon: Icons.directions_bus_rounded,
              color: const Color(0xFFF59E0B),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddBusReservationPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _resOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: Colors.white.withOpacity(0.08), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                        fontSize: 12, color: Colors.white54),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: Colors.white.withOpacity(0.2)),
          ],
        ),
      ),
    );
  }
}
