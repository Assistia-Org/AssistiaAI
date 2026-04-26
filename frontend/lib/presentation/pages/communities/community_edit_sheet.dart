import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/community_provider.dart';
import '../../../domain/entities/community/community.dart';

enum CommunityEditMode { name, description }

class CommunityEditSheet extends StatefulWidget {
  final WidgetRef ref;
  final Community community;
  final CommunityEditMode mode;

  const CommunityEditSheet({
    super.key,
    required this.ref,
    required this.community,
    required this.mode,
  });

  @override
  State<CommunityEditSheet> createState() => _CommunityEditSheetState();
}

class _CommunityEditSheetState extends State<CommunityEditSheet> {
  late final TextEditingController _controller;
  bool _isLoading = false;
  String? _error;

  // Character limits
  static const int _nameMaxLength = 30;
  static const int _descMaxLength = 150;

  int get _maxLength =>
      widget.mode == CommunityEditMode.name ? _nameMaxLength : _descMaxLength;

  String get _title =>
      widget.mode == CommunityEditMode.name ? 'Grup Adını Değiştir' : 'Açıklamayı Değiştir';

  String get _hint =>
      widget.mode == CommunityEditMode.name ? 'Grup adı...' : 'Grup açıklaması...';

  String get _currentValue =>
      widget.mode == CommunityEditMode.name
          ? widget.community.name
          : (widget.community.description ?? '');

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _currentValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      setState(() => _error = 'Bu alan boş bırakılamaz.');
      return;
    }
    if (value == _currentValue) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await widget.ref.read(communityControllerProvider).updateCommunity(
        id: widget.community.id,
        name: widget.mode == CommunityEditMode.name ? value : null,
        description: widget.mode == CommunityEditMode.description ? value : null,
      );
      widget.ref.invalidate(myCommunitiesProvider);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesc = widget.mode == CommunityEditMode.description;
    final remaining = _maxLength - _controller.text.length;
    final isOverLimit = remaining < 0;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.fromLTRB(25, 16, 25, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 44, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _title,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1B232A),
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
                    child: const Icon(Icons.close_rounded, size: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Input field
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FA),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _error != null
                      ? Colors.redAccent.withValues(alpha: 0.4)
                      : isOverLimit
                          ? Colors.redAccent.withValues(alpha: 0.4)
                          : Colors.grey.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              child: TextField(
                controller: _controller,
                maxLines: isDesc ? 4 : 1,
                maxLength: _maxLength,
                buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
                    null, // hide default counter
                onChanged: (_) => setState(() => _error = null),
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF1B232A),
                ),
                decoration: InputDecoration(
                  hintText: _hint,
                  hintStyle: GoogleFonts.inter(
                    color: Colors.grey[400],
                    fontSize: 15,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),

            // Counter + error row
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_error != null)
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.redAccent, size: 14),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _error!,
                            style: GoogleFonts.inter(
                              color: Colors.redAccent,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  const Spacer(),
                Text(
                  '${_controller.text.length} / $_maxLength',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isOverLimit ? Colors.redAccent : Colors.grey[400],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: (_isLoading || isOverLimit) ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B232A),
                  disabledBackgroundColor: Colors.grey[200],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        'Kaydet',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
