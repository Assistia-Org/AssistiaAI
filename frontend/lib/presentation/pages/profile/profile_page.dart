import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

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
                // Dark Header Section (Empty or with Title)
                _buildDarkHeader(),

                // White Body Section with Overlap
                Transform.translate(
                  offset: const Offset(0, -30),
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Profile Avatar Overlapping the Header
                        _buildOverlappingAvatar(),
                        
                        const SizedBox(height: 15),
                        Text(
                          'Alperen',
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          'alper@example.com',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                        
                        const SizedBox(height: 30),
                        _buildStats(),
                        
                        const SizedBox(height: 20),
                        _buildSettingsList(context),
                        
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

  Widget _buildDarkHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 50, bottom: 40),
      width: double.infinity,
      color: const Color(0xFF1B232A),
      child: Center(
        child: Text(
          'Profil',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildOverlappingAvatar() {
    return Transform.translate(
      offset: const Offset(0, -50), // Half of the avatar height (radius 50)
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage('https://i.pravatar.cc/300'),
            ),
          ),
          Positioned(
            bottom: 5,
            right: 5,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.cyanAccent,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.camera_alt_rounded, color: Colors.black, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25),
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('12', 'Topluluk'),
          _buildStatItem('45', 'Görev'),
          _buildStatItem('8', 'Seyahat'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String val, String label) {
    return Column(
      children: [
        Text(
          val,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsList(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 10, bottom: 15),
            child: Text(
              "Hesap Ayarları",
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          _buildSettingItem(Icons.person_outline_rounded, 'Hesap Bilgileri'),
          _buildSettingItem(Icons.notifications_none_rounded, 'Bildirimler'),
          _buildSettingItem(Icons.security_rounded, 'Güvenlik'),
          _buildSettingItem(Icons.palette_outlined, 'Görünüm'),
          _buildSettingItem(Icons.help_outline_rounded, 'Yardım & Destek'),
          const SizedBox(height: 20),
          _buildSettingItem(Icons.logout_rounded, 'Çıkış Yap', color: Colors.redAccent),
        ],
      ),
    );
  }

  Widget _buildSettingItem(IconData icon, String title, {Color? color}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (color ?? const Color(0xFF1B232A)).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color ?? const Color(0xFF1B232A), size: 22),
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: color ?? Colors.black87,
          ),
        ),
        trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
        onTap: () {},
      ),
    );
  }
}
