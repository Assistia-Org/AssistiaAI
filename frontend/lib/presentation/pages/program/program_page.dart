import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
            child: Container(color: const Color(0xFF141414)),
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
                        Padding(
                          padding: const EdgeInsets.only(left: 30, top: 20 ,bottom: 20),
                          child: Text(
                            "Günlük Program",
                            style: GoogleFonts.inter(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const Divider(height: 1),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                          itemCount: 6,
                          itemBuilder: (context, index) {
                            return _buildTimelineItem(
                              '${08 + index}:00',
                              'Görev Başlığı ${index + 1}',
                              'Bu görev için açıklama metni buraya gelecek.',
                              index % 3 == 0 ? Colors.blueAccent : index % 3 == 1 ? Colors.orange : Colors.green,
                            );
                          },
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
      color: const Color(0xFF141414),
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
