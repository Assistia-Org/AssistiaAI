import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/community_provider.dart';
import '../../providers/invitation_provider.dart';
import '../../providers/auth_provider.dart';
import '../../../domain/entities/community/community.dart';
import '../../../domain/entities/user/user.dart';
import '../../widgets/custom_text_field.dart';
import 'community_edit_sheet.dart';

class CommunityDetailPage extends ConsumerWidget {
  final Community community;

  const CommunityDetailPage({super.key, required this.community});

  Color _typeColor(String type) {
    switch (type) {
      case 'Aile':
        return const Color(0xFF0EA5E9);
      case 'Teknoloji':
        return const Color(0xFF8B5CF6);
      case 'Seyahat':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF64748B);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final communitiesAsync = ref.watch(myCommunitiesProvider);
    final currentCommunity = communitiesAsync.when<Community>(
      data: (list) {
        Community? found;
        for (final item in list) {
          if (item.id == community.id) {
            found = item;
            break;
          }
        }
        return found ?? community;
      },
      loading: () => community,
      error: (_, __) => community,
    );
    final currentUser = ref.watch(currentUserProvider);
    final isOwner = currentUser != null && currentCommunity.isOwner(currentUser.id);
    final accentColor = _typeColor(currentCommunity.type);

    return Scaffold(
      backgroundColor: const Color(0xFFEAEFF5),
      body: Stack(
        children: [
          // Dark header background
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 280,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF1B232A),
                    Color.lerp(const Color(0xFF1B232A), accentColor, 0.25)!,
                  ],
                ),
              ),
            ),
          ),

          // Content
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // --- App Bar ---
              SliverAppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                pinned: false,
                leading: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    margin: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
                actions: [
                  // Settings button
                  GestureDetector(
                    onTap: () => _showSettingsMenu(context, ref, currentCommunity, isOwner),
                    child: Container(
                      margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.settings_rounded,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),

              // --- Hero Header ---
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Type badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: accentColor.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          currentCommunity.type.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: accentColor,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        currentCommunity.name,
                        style: GoogleFonts.inter(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        currentCommunity.description?.isNotEmpty == true
                            ? currentCommunity.description!
                            : 'Henüz bir açıklama eklenmedi.',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white60,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Stats Row
                      Row(
                        children: [
                          _buildStatChip(
                            icon: Icons.people_alt_rounded,
                            label: '${currentCommunity.members.length} Üye',
                            color: accentColor,
                          ),
                          const SizedBox(width: 12),
                          _buildStatChip(
                            icon: Icons.verified_rounded,
                            label: isOwner ? 'Yönetici' : 'Üye',
                            color: isOwner ? const Color(0xFFF59E0B) : const Color(0xFF64748B),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),

              // --- White card body ---
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFEAEFF5),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(25),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Members header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Üyeler',
                              style: GoogleFonts.inter(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1B232A),
                              ),
                            ),
                            if (isOwner)
                              GestureDetector(
                                onTap: () => _showAddMemberSheet(context, ref, currentCommunity),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1B232A),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.person_add_alt_1_rounded,
                                          color: Colors.white, size: 16),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Davet Et',
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
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),

              // --- Members list ---
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final member = currentCommunity.members[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25),
                      child: _buildMemberTile(context, ref, currentCommunity, member, accentColor, isOwner),
                    );
                  },
                  childCount: currentCommunity.members.length,
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberTile(
    BuildContext context,
    WidgetRef ref,
    Community community,
    CommunityMember member,
    Color accentColor,
    bool isOwner,
  ) {
    final isOwnerMember = member.role == 'owner';
    final canRemove = isOwner && !isOwnerMember;
    return GestureDetector(
      onTap: canRemove
          ? () => _showMemberOptions(context, ref, community, member)
          : null,
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isOwnerMember ? accentColor : Colors.grey.shade200,
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 22,
              backgroundColor: accentColor.withValues(alpha: 0.15),
              backgroundImage: member.user.avatarUrl != null
                  ? NetworkImage(member.user.avatarUrl!)
                  : null,
              child: member.user.avatarUrl == null
                  ? Text(
                      member.user.displayName[0].toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.user.displayName,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: const Color(0xFF1B232A),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (isOwnerMember)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Yönetici',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: accentColor,
                          ),
                        ),
                      )
                    else
                      Text(
                        'Üye',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (canRemove)
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.redAccent,
              size: 20,
            ),
        ],
      ),
    ),
    );
  }

  void _showMemberOptions(
    BuildContext context,
    WidgetRef ref,
    Community community,
    CommunityMember member,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            // Member info row
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundImage: member.user.avatarUrl != null
                      ? NetworkImage(member.user.avatarUrl!)
                      : null,
                  child: member.user.avatarUrl == null
                      ? Text(member.user.displayName[0].toUpperCase())
                      : null,
                ),
                const SizedBox(width: 14),
                Text(
                  member.user.displayName,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1B232A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () async {
                Navigator.pop(ctx);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                    title: const Text('Üyeyi Çıkar'),
                    content: Text(
                        '${member.user.displayName} adlı üyeyi gruptan çıkarmak istediğinize emin misiniz?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('İptal'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Çıkar'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await _removeMember(ref, community, member);
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.person_remove_alt_1_rounded,
                          color: Colors.redAccent, size: 22),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gruptan Çıkar',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.redAccent,
                          ),
                        ),
                        Text(
                          'Üye gruptan kaldırılacak',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsOption({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final bg = isDestructive
        ? Colors.red.withValues(alpha: 0.06)
        : const Color(0xFFF7F8FA);
    final borderColor = isDestructive
        ? Colors.red.withValues(alpha: 0.15)
        : Colors.grey.withValues(alpha: 0.15);
    final iconBg = isDestructive
        ? Colors.red.withValues(alpha: 0.1)
        : color.withValues(alpha: 0.1);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDestructive ? Colors.redAccent : const Color(0xFF1B232A),
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
        ),
      ),
    );
  }

  void _showEditSheet(
    BuildContext context,
    WidgetRef ref,
    Community community,
    CommunityEditMode mode,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CommunityEditSheet(
        ref: ref,
        community: community,
        mode: mode,
      ),
    );
  }

  void _showSettingsMenu(
    BuildContext context,
    WidgetRef ref,
    Community community,
    bool isOwner,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Ayarlar',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1B232A),
              ),
            ),
            const SizedBox(height: 20),

            // Edit options — only for owner
            if (isOwner) ...[
              _buildSettingsOption(
                icon: Icons.edit_rounded,
                label: 'Grup Adını Değiştir',
                subtitle: 'Topluluk ismini güncelle',
                color: const Color(0xFF1B232A),
                onTap: () {
                  Navigator.pop(ctx);
                  _showEditSheet(context, ref, community, CommunityEditMode.name);
                },
              ),
              const SizedBox(height: 12),
              _buildSettingsOption(
                icon: Icons.description_rounded,
                label: 'Açıklamayı Değiştir',
                subtitle: 'Topluluk açıklamasını güncelle',
                color: const Color(0xFF1B232A),
                onTap: () {
                  Navigator.pop(ctx);
                  _showEditSheet(context, ref, community, CommunityEditMode.description);
                },
              ),
              const SizedBox(height: 12),
            ],

            // Delete / Leave option
            _buildSettingsOption(
              icon: isOwner ? Icons.delete_forever_rounded : Icons.exit_to_app_rounded,
              label: isOwner ? 'Grubu Sil' : 'Gruptan Ayrıl',
              subtitle: isOwner ? 'Grup kalıcı olarak silinecek' : 'Bu gruptan ayrılırsın',
              color: Colors.redAccent,
              isDestructive: true,
              onTap: () {
                Navigator.pop(ctx);
                if (isOwner) {
                  _confirmDeleteCommunity(context, ref, community);
                } else {
                  _confirmLeaveCommunity(context, ref, community);
                }
              },
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  void _showAddMemberSheet(
    BuildContext context,
    WidgetRef ref,
    Community community,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddMemberSheet(ref: ref, community: community),
    );
  }

  Future<void> _removeMember(
    WidgetRef ref,
    Community community,
    CommunityMember memberToRemove,
  ) async {
    try {
      await ref
          .read(communityControllerProvider)
          .removeCommunityMember(community.id, memberToRemove.user.id);
      ref.invalidate(myCommunitiesProvider);
    } catch (e) {
      debugPrint('Error removing member: $e');
    }
  }

  Future<void> _confirmDeleteCommunity(
    BuildContext context,
    WidgetRef ref,
    Community community,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
            ),
            const SizedBox(width: 12),
            const Text('Grubu Sil'),
          ],
        ),
        content: const Text('Bu grubu silmek istediğinize emin misiniz?\nBu işlem geri alınamaz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Evet, Sil'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!context.mounted) return;
      try {
        await ref.read(communityControllerProvider).deleteCommunity(community.id);
        ref.invalidate(myCommunitiesProvider);
        if (context.mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Grup başarıyla silindi.')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          final msg = e.toString().replaceFirst('Exception: ', '');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Silme işlemi başarısız: $msg')),
          );
        }
      }
    }
  }

  Future<void> _confirmLeaveCommunity(
    BuildContext context,
    WidgetRef ref,
    Community community,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Gruptan Ayrıl'),
        content: const Text('Bu gruptan ayrılmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Ayrıl'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!context.mounted) return;
      try {
        await ref.read(communityControllerProvider).leaveCommunity(community.id);
        ref.invalidate(myCommunitiesProvider);
        if (context.mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gruptan başarıyla ayrıldınız.')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          final msg = e.toString().replaceFirst('Exception: ', '');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ayrılma işlemi başarısız: $msg')),
          );
        }
      }
    }
  }
}

// ─── Add Member Sheet ─────────────────────────────────────────────────────────

class _AddMemberSheet extends StatefulWidget {
  final WidgetRef ref;
  final Community community;
  const _AddMemberSheet({required this.ref, required this.community});

  @override
  State<_AddMemberSheet> createState() => _AddMemberSheetState();
}

class _AddMemberSheetState extends State<_AddMemberSheet> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _emailError;

  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
  );

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Üye Davet Et',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Davet etmek istediğiniz kullanıcının e-posta adresini girin.',
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 25),
            CustomTextField(
              hintText: 'E-posta adresi',
              prefixIcon: Icons.email_outlined,
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              onChanged: (_) {
                if (_emailError != null) setState(() => _emailError = null);
              },
            ),
            if (_emailError != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _emailError!,
                      style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleAddMember,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B232A),
                  disabledBackgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Davet Gönder',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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

  Future<void> _handleAddMember() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    if (!_emailRegex.hasMatch(email)) {
      setState(() => _emailError = 'Geçersiz e-posta formatı.');
      return;
    }

    setState(() {
      _isLoading = true;
      _emailError = null;
    });

    try {
      await widget.ref
          .read(invitationControllerProvider.notifier)
          .sendInvitation(
            communityId: widget.community.id,
            inviteeEmail: email,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Davet başarıyla gönderildi!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _emailError = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
