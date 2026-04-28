import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/community_provider.dart';
import '../providers/auth_provider.dart';
import '../../domain/entities/community/community.dart';

class AssignmentSelector extends ConsumerStatefulWidget {
  final Function(String? communityId, List<String> assignedTo) onChanged;
  
  const AssignmentSelector({super.key, required this.onChanged});

  @override
  ConsumerState<AssignmentSelector> createState() => _AssignmentSelectorState();
}

class _AssignmentSelectorState extends ConsumerState<AssignmentSelector> {
  String _selectionType = 'personal'; // 'personal', 'community_all', 'community_member'
  String? _selectedCommunityId;
  List<String> _selectedMemberIds = [];

  @override
  Widget build(BuildContext context) {
    final myCommunitiesAsync = ref.watch(myCommunitiesProvider);
    final currentUser = ref.watch(currentUserProvider);

    return myCommunitiesAsync.when(
      data: (communities) {
        // Filter communities where user is owner
        final ownedCommunities = communities.where((c) => c.ownerId == currentUser?.id).toList();
        
        if (ownedCommunities.isEmpty) {
          return const SizedBox.shrink(); // Hide if not an owner of any community
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Text(
              'ATAMA',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildOption(
                    title: 'Kişisel',
                    subtitle: 'Sadece benim takvimimde görünsün',
                    isSelected: _selectionType == 'personal',
                    onTap: () {
                      setState(() {
                        _selectionType = 'personal';
                        _selectedCommunityId = null;
                        _selectedMemberIds = [];
                      });
                      widget.onChanged(null, []);
                    },
                    icon: Icons.person_rounded,
                  ),
                  const SizedBox(height: 12),
                  _buildOption(
                    title: 'Topluluk',
                    subtitle: 'Tüm topluluk üyelerine ata',
                    isSelected: _selectionType == 'community_all',
                    onTap: () {
                      if (_selectedCommunityId == null && ownedCommunities.isNotEmpty) {
                        _selectedCommunityId = ownedCommunities.first.id;
                      }
                      setState(() {
                        _selectionType = 'community_all';
                        _selectedMemberIds = [];
                      });
                      widget.onChanged(_selectedCommunityId, []);
                    },
                    icon: Icons.groups_rounded,
                  ),
                  if (_selectionType == 'community_all') ...[
                    const SizedBox(height: 12),
                    _buildCommunityDropdown(ownedCommunities),
                  ],
                  const SizedBox(height: 12),
                  _buildOption(
                    title: 'Üye',
                    subtitle: 'Topluluktan belirli bir kişiye ata',
                    isSelected: _selectionType == 'community_member',
                    onTap: () {
                      if (_selectedCommunityId == null && ownedCommunities.isNotEmpty) {
                        _selectedCommunityId = ownedCommunities.first.id;
                      }
                      setState(() {
                        _selectionType = 'community_member';
                      });
                      widget.onChanged(_selectedCommunityId, _selectedMemberIds);
                    },
                    icon: Icons.person_add_alt_1_rounded,
                  ),
                  if (_selectionType == 'community_member' && _selectedCommunityId != null) ...[
                    const SizedBox(height: 12),
                    _buildCommunityDropdown(ownedCommunities),
                    const SizedBox(height: 16),
                    _buildMemberMultiSelector(ownedCommunities.firstWhere((c) => c.id == _selectedCommunityId)),
                  ],
                ],
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildOption({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0EA5E9).withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF0EA5E9) : Colors.white.withOpacity(0.05),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? const Color(0xFF0EA5E9) : Colors.white54, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: Color(0xFF0EA5E9), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCommunityDropdown(List<Community> communities) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCommunityId,
          dropdownColor: const Color(0xFF0F172A),
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down_rounded, color: Colors.white54),
          onChanged: (val) {
            setState(() {
              _selectedCommunityId = val;
              _selectedMemberIds = []; // Reset members when community changes
            });
            widget.onChanged(val, []);
          },
          items: communities.map((c) => DropdownMenuItem(
            value: c.id,
            child: Text(c.name, style: const TextStyle(color: Colors.white, fontSize: 13)),
          )).toList(),
        ),
      ),
    );
  }

  Widget _buildMemberMultiSelector(Community community) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Üye Seçin',
          style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: community.members.map((m) {
            final isSelected = _selectedMemberIds.contains(m.user.id);
            return FilterChip(
              label: Text(
                m.user.displayName,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontSize: 12,
                ),
              ),
              selected: isSelected,
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedMemberIds.add(m.user.id);
                  } else {
                    _selectedMemberIds.remove(m.user.id);
                  }
                });
                widget.onChanged(_selectedCommunityId, _selectedMemberIds);
              },
              backgroundColor: const Color(0xFF0F172A),
              selectedColor: const Color(0xFF0EA5E9).withOpacity(0.4),
              checkmarkColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? const Color(0xFF0EA5E9) : Colors.white.withOpacity(0.1),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
