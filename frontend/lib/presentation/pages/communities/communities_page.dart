import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/dummy_data.dart';

class CommunitiesPage extends StatelessWidget {
  const CommunitiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> communities = DummyData.communities;
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
                _buildSearchHeader(context),
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
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Topluluklarım",
                                style: GoogleFonts.inter(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              Text(
                                "${communities.length}",
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 25),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 25),
                          itemCount: communities.length,
                          itemBuilder: (context, index) {
                            final comm = communities[index];
                            final Color communityColor = _getCommunityColor(comm['type']);
                            return _buildCommunityCard(
                              name: comm['name'],
                              type: comm['type'],
                              description: 'Henüz bir açıklama eklenmedi.', // Backend standard handling
                              members: List<Map<String, dynamic>>.from(comm['members']),
                              color: communityColor,
                            );
                          },
                        ),
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

  Color _getCommunityColor(String type) {
    switch (type) {
      case 'Aile': return const Color(0xFF0EA5E9);
      case 'Teknoloji': return const Color(0xFF8B5CF6);
      case 'Seyahat': return const Color(0xFFF59E0B);
      default: return const Color(0xFF64748B);
    }
  }

  Widget _buildSearchHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 40, left: 25, right: 25, bottom: 50),
      color: const Color(0xFF1B232A),
      child: Row(
        children: [
          // Glassmorphism Search Bar
          Expanded(
            child: Container(
              height: 55,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: TextField(
                style: GoogleFonts.inter(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Topluluk ara...',
                  hintStyle: GoogleFonts.inter(color: Colors.white38, fontSize: 14),
                  prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 17),
                ),
              ),
            ),
          ),
          const SizedBox(width: 15),
          // Add Button
          GestureDetector(
            onTap: () {},
            child: Container(
              height: 55,
              width: 55,
              decoration: BoxDecoration(
                color: Colors.cyanAccent,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.cyanAccent.withValues(alpha: 0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(Icons.add, color: Colors.black, size: 28),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityCard({
    required String name,
    required String type,
    required String description,
    required List<Map<String, dynamic>> members,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Left Color Rail
            Container(
              width: 8,
              color: color,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            type.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: color,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const Icon(Icons.more_horiz, color: Colors.grey, size: 20),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      name,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1B232A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.grey[500],
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        // Avatar Stack
                        _buildAvatarStack(members),
                        const SizedBox(width: 12),
                        Text(
                          '${members.length} üye',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1B232A),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Görüntüle',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarStack(List<Map<String, dynamic>> members) {
    int showCount = members.length > 4 ? 4 : members.length;
    return SizedBox(
      height: 30,
      width: (showCount * 20.0) + 10,
      child: Stack(
        children: List.generate(showCount, (index) {
          return Positioned(
            left: index * 20.0,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 14,
                backgroundImage: NetworkImage(members[index]['avatar']),
              ),
            ),
          );
        }),
      ),
    );
  }
}
