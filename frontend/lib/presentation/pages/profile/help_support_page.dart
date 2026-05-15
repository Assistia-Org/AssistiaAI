import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B232A), // Match header color
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B232A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Yardım & Destek',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroSection(),
            Container(
              color: Colors.white, // Rest of the content stays white
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 30),
                  _buildSectionTitle('Sıkça Sorulan Sorular'),
                  _buildFAQList(),
                  const SizedBox(height: 30),
                  _buildSectionTitle('Bize Ulaşın'),
                  _buildContactOptions(),
                  const SizedBox(height: 40),
                  _buildAppInfo(),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(25, 20, 25, 40),
      decoration: const BoxDecoration(
        color: Color(0xFF1B232A),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.cyanAccent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.support_agent_rounded,
              color: Colors.cyanAccent,
              size: 50,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Size nasıl yardımcı olabiliriz?',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sorularınız için SSS bölümüne göz atabilir veya doğrudan bizimle iletişime geçebilirsiniz.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white70,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF1B232A),
        ),
      ),
    );
  }

  Widget _buildFAQList() {
    final faqs = [
      {
        'q': 'AssistiaAI nedir?',
        'a': 'AssistiaAI, yapay zeka destekli bir kişisel asistan ve topluluk yönetim uygulamasıdır. Görevlerinizi, rezervasyonlarınızı ve topluluk etkinliklerinizi tek bir yerden yönetmenizi sağlar.'
      },
      {
        'q': 'Konum bilgisini nasıl kullanırım?',
        'a': 'Görev veya rezervasyon eklerken konum eklediğinizde, detay sayfasında mini bir harita görünür. Haritaya tıklayarak navigasyonu başlatabilirsiniz.'
      },
      {
        'q': 'Topluluklara nasıl katılırım?',
        'a': 'Topluluklar sayfasından ilginizi çeken toplulukları arayabilir veya size gönderilen davet kodlarını kullanarak katılabilirsiniz.'
      },
      {
        'q': 'Verilerim güvende mi?',
        'a': 'Evet, AssistiaAI verilerinizi uçtan uca şifreleme ve güvenli bulut altyapısı ile korur. Kişisel verileriniz asla üçüncü taraflarla paylaşılmaz.'
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Column(
        children: faqs.map((faq) => _buildFAQItem(faq['q']!, faq['a']!)).toList(),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            question,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1B232A),
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Text(
              answer,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactOptions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: _buildContactCard(
        Icons.mail_outline_rounded,
        'E-posta ile Bize Ulaşın',
        'support@assistia.ai',
        const Color(0xFF3498DB),
        () => _launchEmail(),
      ),
    );
  }

  Widget _buildContactCard(IconData icon, String title, String sub, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sub,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: color.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: color.withValues(alpha: 0.3), size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildAppInfo() {
    return Center(
      child: Column(
        children: [
          const Opacity(
            opacity: 0.3,
            child: FlutterLogo(size: 30),
          ),
          const SizedBox(height: 10),
          Text(
            'AssistiaAI v1.0.4',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey[400],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '© 2024 Assistia. Tüm hakları saklıdır.',
            style: GoogleFonts.inter(
              fontSize: 10,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@assistia.ai',
      query: 'subject=AssistiaAI Destek Talebi',
    );
    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    }
  }
}
