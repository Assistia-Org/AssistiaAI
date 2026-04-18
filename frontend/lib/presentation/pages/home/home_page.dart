import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Professional light background to make cards pop
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
            clipBehavior: Clip.none,
            child: Column(
              children: [
                // Dark Header Section
                _buildHeader(),
                
                // White Body Section with Overlap
                Transform.translate(
                  offset: const Offset(0, -30),
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8F9FA), // Changed from white to match scaffold for card contrast
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Can'a Merhaba",
                          style: GoogleFonts.inter(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 25),
                        // Daily Summaries Card (Beautified with premium look)
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              // Layered shadows for a more realistic float effect
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 40,
                                offset: const Offset(0, 15),
                              ),
                              BoxShadow(
                                color: const Color(0xFF1B232A).withValues(alpha: 0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Günün Özetleri",
                                style: GoogleFonts.inter(
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 25),
                              _buildDailySummaries(),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 35),
                        _buildSectionHeader("Rezervasyonlarım"),
                        const SizedBox(height: 15),
                        _buildReservationsList(),

                        const SizedBox(height: 35),
                        _buildSectionHeader("Görevlerim"),
                        const SizedBox(height: 15),
                        _buildTasksList(),

                        const SizedBox(height: 35),
                        _buildSectionHeader("Toplantılarım"),
                        const SizedBox(height: 15),
                        _buildMeetingsList(),

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
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.blueAccent.withValues(alpha: 0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
              gradient: const LinearGradient(
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
                borderRadius: BorderRadius.circular(20), // Fully rounded like the image
              ),
              child: Text(
                'Bu bir örnek yapay zeka mesajı örneğidir',
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

  Widget _buildDailySummaries() {
    final List<Map<String, dynamic>> summaries = [
      {'icon': Icons.format_list_bulleted_rounded},
      {'icon': Icons.assignment_turned_in_outlined},
      {'icon': Icons.check_rounded},
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

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: isLast ? null : LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isGray 
                ? [Colors.grey[50]!, Colors.grey[100]!]
                : [const Color(0xFFE0F2F1), const Color(0xFFB2DFDB).withValues(alpha: 0.5)],
            ),
            borderRadius: BorderRadius.circular(18),
            border: isLast ? null : Border.all(color: Colors.white, width: 1.5), // Glassy edge
            boxShadow: isLast ? null : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            data['icon'],
            color: isLast ? Colors.grey[300] : (isGray ? Colors.black87 : const Color(0xFF4A9090)),
            size: 24,
          ),
        ),
        if (!isLast && !isGray)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: Color(0xFF4A9090),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, size: 10, color: Colors.white),
            ),
          ),
        if (isGray)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.grey[500],
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, size: 10, color: Colors.white),
            ),
          ),
      ],
    );
  }

  Widget _buildReservationsList() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      clipBehavior: Clip.none,
      child: Row(
        children: [
          _buildInfoCard(
            type: "Uçuş",
            title: "IST - AYT",
            infoTitle: "Havayolu",
            infoValue: "Türk Hava Yolları",
            time: "18:00 - 20:00",
            icon: Icons.flight_takeoff_rounded,
            color: const Color(0xFF4A9090),
          ),
          const SizedBox(width: 15),
          _buildInfoCard(
            type: "Otel",
            title: "Sea View Resort",
            infoTitle: "Durum",
            infoValue: "Onaylandı",
            time: "Check-in: 14:00",
            icon: Icons.hotel_rounded,
            color: const Color(0xFF1A4A7A),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksList() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      clipBehavior: Clip.none,
      child: Row(
        children: [
          _buildInfoCard(
            type: "Acil",
            title: "Sunum Dosyaları",
            infoTitle: "Proje",
            infoValue: "Assistia AI",
            time: "Bugün 17:00'ye kadar",
            icon: Icons.description_rounded,
            color: Colors.orangeAccent,
          ),
          const SizedBox(width: 15),
          _buildInfoCard(
            type: "Normal",
            title: "E-postaları Yanıtla",
            infoTitle: "Kategori",
            infoValue: "Müşteri Hizmetleri",
            time: "Bugün",
            icon: Icons.mail_outline_rounded,
            color: Colors.blueGrey,
          ),
        ],
      ),
    );
  }

  Widget _buildMeetingsList() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      clipBehavior: Clip.none,
      child: Row(
        children: [
          _buildInfoCard(
            type: "Online",
            title: "Haftalık Senkron",
            infoTitle: "Platform",
            infoValue: "Google Meet",
            time: "10:30 - 11:30",
            icon: Icons.video_camera_front_rounded,
            color: Colors.purple.shade400,
          ),
          const SizedBox(width: 15),
          _buildInfoCard(
            type: "Yüz Yüze",
            title: "Müşteri Toplantısı",
            infoTitle: "Konum",
            infoValue: "Zorlu Center",
            time: "14:00 - 15:30",
            icon: Icons.groups_rounded,
            color: Colors.teal.shade700,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String type,
    required String title,
    required String infoTitle,
    required String infoValue,
    required String time,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.black.withValues(alpha: 0.12), width: 1.2), // Even sharper border
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 1,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 70,
            width: double.infinity,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
            ),
            padding: const EdgeInsets.all(15),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  infoTitle,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  infoValue,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  time,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[500],
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
