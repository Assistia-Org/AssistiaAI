import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/community_provider.dart';
import '../../providers/invitation_provider.dart';
import '../../providers/auth_provider.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/community/community.dart';
import '../../../domain/entities/user/user.dart';
import '../../widgets/custom_text_field.dart';

class CommunityDetailPage extends ConsumerWidget {
  final Community community;

  const CommunityDetailPage({super.key, required this.community});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final communitiesAsync = ref.watch(myCommunitiesProvider);
    final currentCommunity = communitiesAsync.when<Community>(
      data: (list) {
        // Manual search to avoid all Generic variance issues with firstWhere/orElse
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          currentCommunity.name,
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(currentCommunity),
          Padding(
            padding: const EdgeInsets.all(25),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Üyeler (${currentCommunity.members.length})",
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => _showAddMemberSheet(context, ref, currentCommunity),
                  icon: const Icon(Icons.person_add, color: Colors.blue),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              itemCount: currentCommunity.members.length,
              itemBuilder: (context, index) {
                final member = currentCommunity.members[index];
                return _buildMemberTile(context, ref, currentCommunity, member);
              },
            ),
          ),
          // --- Action Buttons ---
          Padding(
            padding: const EdgeInsets.all(25),
            child: Consumer(
              builder: (context, ref, child) {
                final currentUser = ref.watch(currentUserProvider);
                if (currentUser == null) return const SizedBox.shrink();

                final isOwner = currentCommunity.isOwner(currentUser.id);

                return SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () => isOwner 
                      ? _confirmDeleteCommunity(context, ref, currentCommunity)
                      : _confirmLeaveCommunity(context, ref, currentCommunity),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
                      foregroundColor: Colors.redAccent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.3)),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(isOwner ? Icons.delete_outline : Icons.exit_to_app),
                        const SizedBox(width: 8),
                        Text(
                          isOwner ? 'Grubu Sil' : 'Gruptan Ayrıl',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Community community) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              community.type.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
          const SizedBox(height: 15),
          Text(
            "Topluluk Hakkında",
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Bu topluluk ${community.name} üyeleri için oluşturulmuştur. Burada paylaşımlar yapabilir ve etkinlikler düzenleyebilirsiniz.",
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.5,
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
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: member.user.avatarUrl != null
                ? NetworkImage(member.user.avatarUrl!)
                : null,
            child: member.user.avatarUrl == null
                ? Text(member.user.displayName[0])
                : null,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.user.displayName,
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                ),
                Text(
                  member.role,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          if (member.role != 'owner')
            IconButton(
              onPressed: () => _removeMember(ref, community, member),
              icon: const Icon(
                Icons.remove_circle_outline,
                color: Colors.redAccent,
                size: 20,
              ),
            ),
        ],
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
}

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
  bool _isChecking = false;
  String? _emailError;
  Map<String, dynamic>? _foundUser; // holds user data preview

  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
  );

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _checkEmail() async {
    final email = _emailController.text.trim();

    // 1. Format check
    if (!_emailRegex.hasMatch(email)) {
      setState(() {
        _emailError = 'Geçersiz e-posta formatı.';
        _foundUser = null;
      });
      return;
    }

    setState(() {
      _isChecking = true;
      _emailError = null;
      _foundUser = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.accessTokenKey);
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.userByEmail(email)}'),
        headers: {
          ...AppConstants.baseHeaders,
          if (token != null) ...AppConstants.authHeader(token),
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _foundUser = jsonDecode(response.body) as Map<String, dynamic>;
          _emailError = null;
        });
      } else if (response.statusCode == 404) {
        setState(() {
          _emailError = 'Bu hesaba ait bir kişi bulunamadı.';
          _foundUser = null;
        });
      } else {
        setState(() {
          _emailError = 'Kullanıcı doğrulanamadı.';
          _foundUser = null;
        });
      }
    } catch (_) {
      setState(() {
        _emailError = 'Bağlantı hatası. Lütfen tekrar deneyin.';
        _foundUser = null;
      });
    } finally {
      setState(() => _isChecking = false);
    }
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
                width: 40,
                height: 4,
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
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Davet etmek istediğiniz kullanıcının e-posta adresini girin.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 25),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CustomTextField(
                    hintText: 'E-posta adresi',
                    prefixIcon: Icons.email_outlined,
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (_) {
                      // Clear previous results when typing
                      if (_foundUser != null || _emailError != null) {
                        setState(() {
                          _foundUser = null;
                          _emailError = null;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 55,
                  width: 55,
                  child: ElevatedButton(
                    onPressed: _isChecking ? null : _checkEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: _isChecking
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.search, color: Colors.white),
                  ),
                ),
              ],
            ),
            // Error message
            if (_emailError != null) ...
              [
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.redAccent, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _emailError!,
                        style: GoogleFonts.inter(
                          color: Colors.redAccent,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            // User found preview card
            if (_foundUser != null) ...
              [
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                        color: Colors.green.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.green.withValues(alpha: 0.15),
                        child: Text(
                          (_foundUser!['display_name'] as String? ?? '?')
                              .substring(0, 1)
                              .toUpperCase(),
                          style: GoogleFonts.inter(
                            color: Colors.green[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _foundUser!['display_name'] as String? ?? '-',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              _foundUser!['email'] as String? ?? '-',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.check_circle,
                          color: Colors.green, size: 22),
                    ],
                  ),
                ),
              ],
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                // Only enabled when user is confirmed
                onPressed:
                    (_isLoading || _foundUser == null) ? null : _handleAddMember,
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
                        _foundUser == null
                            ? 'Önce Sorgulayın'
                            : 'Davet Gönder',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _foundUser == null
                              ? Colors.grey[500]
                              : Colors.white,
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
    if (_foundUser == null) return;

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();

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
        // Strip the 'Exception: ' prefix for clean display
        final msg = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
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
        title: const Text('Grubu Sil'),
        content: const Text('Bu grubu silmek istediğinize emin misiniz? Bu işlem geri alınamaz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
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
          Navigator.of(context).pop(); // Go back to prev screen
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
        title: const Text('Gruptan Ayrıl'),
        content: const Text('Bu gruptan ayrılmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
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
          Navigator.of(context).pop(); // Go back
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
