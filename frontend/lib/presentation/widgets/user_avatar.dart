import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UserAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String displayName;
  final double radius;
  final TextStyle? textStyle;

  const UserAvatar({
    super.key,
    required this.displayName,
    this.avatarUrl,
    this.radius = 20,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null && avatarUrl!.isNotEmpty && avatarUrl!.startsWith('http')) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(avatarUrl!),
        backgroundColor: Colors.grey[200],
      );
    }

    String initial = '';
    if (displayName.trim().isNotEmpty) {
      final parts = displayName.trim().split(' ');
      if (parts.length > 1) {
        // Alperen Özdemir -> AÖ
        initial = (parts.first[0] + parts.last[0]).toUpperCase();
      } else {
        // Alperen -> A
        initial = parts.first[0].toUpperCase();
      }
    }
    if (initial.isEmpty) initial = '?';
    
    return CircleAvatar(
      radius: radius,
      backgroundColor: _getBackgroundColor(displayName),
      child: Text(
        initial,
        style: textStyle ?? GoogleFonts.inter(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.8,
        ),
      ),
    );
  }

  Color _getBackgroundColor(String name) {
    final List<Color> colors = [
      const Color(0xFF7C3AED), // Purple
      const Color(0xFF3B82F6), // Blue
      const Color(0xFF10B981), // Green
      const Color(0xFFF59E0B), // Amber
      const Color(0xFFEF4444), // Red
      const Color(0xFFEC4899), // Pink
      const Color(0xFF6366F1), // Indigo
    ];
    
    if (name.isEmpty) return colors[0];
    
    final int hash = name.codeUnits.fold(0, (prev, element) => prev + element);
    return colors[hash % colors.length];
  }
}
