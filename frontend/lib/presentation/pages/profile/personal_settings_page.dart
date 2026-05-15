import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';

class PersonalSettingsPage extends ConsumerStatefulWidget {
  const PersonalSettingsPage({super.key});

  @override
  ConsumerState<PersonalSettingsPage> createState() =>
      _PersonalSettingsPageState();
}

class _PersonalSettingsPageState extends ConsumerState<PersonalSettingsPage> {
  late String _selectedTheme;
  late String _selectedLanguage;
  bool _hasChanges = false;

  // ──────────────────────────────────────────────────────────────────────
  // Seçenekler
  // ──────────────────────────────────────────────────────────────────────

  static const _themes = [
    _OptionItem(value: 'light', label: 'Açık', icon: Icons.light_mode_rounded),
    _OptionItem(value: 'dark', label: 'Koyu', icon: Icons.dark_mode_rounded),
    _OptionItem(
        value: 'system', label: 'Sistem', icon: Icons.settings_brightness_rounded),
  ];

  static const _languages = [
    _OptionItem(value: 'tr', label: 'Türkçe', emoji: '🇹🇷'),
    _OptionItem(value: 'en', label: 'English', emoji: '🇬🇧'),
    _OptionItem(value: 'de', label: 'Deutsch', emoji: '🇩🇪'),
    _OptionItem(value: 'fr', label: 'Français', emoji: '🇫🇷'),
  ];

  @override
  void initState() {
    super.initState();
    final s = ref.read(personalSettingsProvider);
    _selectedTheme = s.theme;
    _selectedLanguage = s.language;
  }

  void _checkChanges() {
    final s = ref.read(personalSettingsProvider);
    setState(() {
      _hasChanges =
          _selectedTheme != s.theme || _selectedLanguage != s.language;
    });
  }

  Future<void> _save() async {
    final current = ref.read(personalSettingsProvider);
    final updated = current.copyWith(
      theme: _selectedTheme,
      language: _selectedLanguage,
    );
    try {
      await ref.read(userControllerProvider).updateSettings(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF2ECC71),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline,
                    color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text('Ayarlar kaydedildi',
                    style: GoogleFonts.inter(color: Colors.white)),
              ],
            ),
          ),
        );
        setState(() => _hasChanges = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.redAccent,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            content: Text('Hata: $e',
                style: GoogleFonts.inter(color: Colors.white)),
          ),
        );
      }
    }
  }

  // ──────────────────────────────────────────────────────────────────────
  // Build
  // ──────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authLoadingProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Koyu Arka Plan
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 200,
            child: Container(color: const Color(0xFF1B232A)),
          ),

          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // App Bar
              SliverAppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  'Görünüm & Dil',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                centerTitle: true,
                pinned: true,
                expandedHeight: 120,
              ),

              // İçerik
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 25, vertical: 30),
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
                        // ── Tema Seçimi ──────────────────────────────
                        _buildSectionHeader(
                          icon: Icons.palette_outlined,
                          title: 'Tema',
                          subtitle: 'Uygulama görünümünü özelleştirin',
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: _themes
                              .map((t) => Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: _ThemeCard(
                                        item: t,
                                        isSelected: _selectedTheme == t.value,
                                        onTap: () {
                                          setState(() =>
                                              _selectedTheme = t.value);
                                          _checkChanges();
                                        },
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),

                        const SizedBox(height: 36),

                        // ── Dil Seçimi ───────────────────────────────
                        _buildSectionHeader(
                          icon: Icons.language_rounded,
                          title: 'Dil',
                          subtitle: 'Uygulama dilini seçin',
                        ),
                        const SizedBox(height: 16),
                        ...(_languages.map((l) => _LanguageTile(
                              item: l,
                              isSelected: _selectedLanguage == l.value,
                              onTap: () {
                                setState(() => _selectedLanguage = l.value);
                                _checkChanges();
                              },
                            ))),

                        const SizedBox(height: 40),

                        // ── Kaydet Butonu ────────────────────────────
                        AnimatedOpacity(
                          opacity: _hasChanges ? 1.0 : 0.4,
                          duration: const Duration(milliseconds: 250),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed:
                                  _hasChanges && !isLoading ? _save : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1B232A),
                                disabledBackgroundColor:
                                    const Color(0xFF1B232A),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 18),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18)),
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      'Değişiklikleri Kaydet',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 50),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF1B232A).withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: const Color(0xFF1B232A), size: 22),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Yardımcı Veri Sınıfları
// ──────────────────────────────────────────────────────────────────────────────

class _OptionItem {
  final String value;
  final String label;
  final IconData? icon;
  final String? emoji;

  const _OptionItem({
    required this.value,
    required this.label,
    this.icon,
    this.emoji,
  });
}

// ──────────────────────────────────────────────────────────────────────────────
// Tema Kartı
// ──────────────────────────────────────────────────────────────────────────────

class _ThemeCard extends StatelessWidget {
  final _OptionItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1B232A)
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF1B232A)
                : Colors.grey[200]!,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF1B232A).withValues(alpha: 0.18),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              item.icon,
              color: isSelected ? Colors.white : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              item.label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Dil Tile'ı
// ──────────────────────────────────────────────────────────────────────────────

class _LanguageTile extends StatelessWidget {
  final _OptionItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1B232A).withValues(alpha: 0.04)
              : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF1B232A)
                : Colors.grey[200]!,
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Row(
          children: [
            // Bayrak Emoji
            Text(
              item.emoji ?? '',
              style: const TextStyle(fontSize: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                item.label,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? const Color(0xFF1B232A)
                      : Colors.black87,
                ),
              ),
            ),
            AnimatedScale(
              scale: isSelected ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 220),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFF1B232A),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
