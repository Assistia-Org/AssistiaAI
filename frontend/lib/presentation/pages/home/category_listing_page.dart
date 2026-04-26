import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/event_mapper.dart';
import '../../../data/models/reservation/reservation_model.dart';
import '../../../data/models/task/task_model.dart';
import '../../providers/task_provider.dart';
import '../../providers/daily_program_provider.dart';

// ─── Turkish Date Helpers ─────────────────────────────────────────────────────
const _trMonths = [
  '', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
  'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
];

String _trDate(DateTime dt) =>
    '${dt.day} ${_trMonths[dt.month]} ${dt.year}';

String _trDateShort(DateTime dt) =>
    '${dt.day} ${_trMonths[dt.month]}';

String _trDateTime(DateTime? dt) {
  if (dt == null) return 'Belirtilmedi';
  return '${dt.day} ${_trMonths[dt.month].substring(0, 3)} ${dt.year}, ${DateFormat('HH:mm').format(dt)}';
}

// ─── Design Tokens ────────────────────────────────────────────────────────────
class _AppColors {
  static const background   = Color(0xFFF0EEE9);
  static const surface      = Color(0xFFFAFAF8);
  static const surfaceWhite = Color(0xFFFFFFFF);
  static const border       = Color(0xFFE4E1DC);

  static const text1 = Color(0xFF1A1917);
  static const text2 = Color(0xFF6B6861);
  static const text3 = Color(0xFFA8A49E);

  static const accentOrange = Color(0xFFC7763A);
  static const accentGreen  = Color(0xFF4A7C5F);
  static const accentPurple = Color(0xFF5A4FA3);
  static const accentRed    = Color(0xFFC44040);

  static const pillHighBg   = Color(0xFFFDECEA);
  static const pillHighText = Color(0xFFB83232);
  static const pillMedBg    = Color(0xFFFFF8EA);
  static const pillMedText  = Color(0xFFB8820A);
  static const pillLowBg    = Color(0xFFEAF5EE);
  static const pillLowText  = Color(0xFF2E7D50);
  static const pillDoneBg   = Color(0xFFEAF5EE);
  static const pillDoneText = Color(0xFF2E7D50);

  static const tagBg      = Color(0xFFF0EEE9);
  static const descBg     = Color(0xFFF0EEE9);
  static const deleteBtnBorder = Color(0xFFC44040);
}

// ─── Page ─────────────────────────────────────────────────────────────────────
class CategoryListingPage extends ConsumerStatefulWidget {
  final String title;
  final List<TaskModel>? tasks;
  final List<ReservationModel>? reservations;

  const CategoryListingPage({
    super.key,
    required this.title,
    this.tasks,
    this.reservations,
  });

  @override
  ConsumerState<CategoryListingPage> createState() => _CategoryListingPageState();
}

class _CategoryListingPageState extends ConsumerState<CategoryListingPage> {
  String? _expandedId;

  void _toggleExpand(String id) {
    setState(() {
      _expandedId = (_expandedId == id) ? null : id;
    });
  }

  Future<void> _completeTask(String taskId) async {
    try {
      await ref.read(taskControllerProvider).updateTaskStatus(taskId, 'completed');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Görev başarıyla tamamlandı!',
              style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            backgroundColor: _AppColors.accentGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
        ref.invalidate(dailyProgramByDateProvider(
          DateFormat('yyyy-MM-dd').format(DateTime.now()),
        ));
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnack('Hata: $e');
      }
    }
  }

  Future<void> _deleteTask(String taskId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => _DeleteDialog(),
    );

    if (confirm == true) {
      try {
        await ref.read(taskControllerProvider).deleteTask(taskId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Öğe silindi',
                style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
          ref.invalidate(dailyProgramByDateProvider(
            DateFormat('yyyy-MM-dd').format(DateTime.now()),
          ));
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) _showErrorSnack('Hata: $e');
      }
    }
  }

  void _showErrorSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.dmSans()),
        backgroundColor: _AppColors.accentRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ─── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AppColors.background,
      appBar: _buildAppBar(),
      body: _buildContent(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final count = (widget.tasks?.length ?? 0) + (widget.reservations?.length ?? 0);
    return AppBar(
      backgroundColor: _AppColors.surfaceWhite,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _AppColors.border),
      ),
      title: Text(
        widget.title,
        style: GoogleFonts.dmSerifDisplay(
          color: _AppColors.text1,
          fontSize: 22,
          fontStyle: FontStyle.normal,
        ),
      ),
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: _BackButton(onTap: () => Navigator.pop(context)),
      ),
      actions: [
        if (count > 0)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _AppColors.background,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _AppColors.border),
                ),
                child: Text(
                  '$count öğe',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: _AppColors.text2,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildContent() {
    final hasTasks = widget.tasks != null && widget.tasks!.isNotEmpty;
    final hasReservations = widget.reservations != null && widget.reservations!.isNotEmpty;

    if (!hasTasks && !hasReservations) return _buildEmptyState();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        if (hasTasks) ...[
          _SectionHeader(
            label: 'Bugün · ${_trDateShort(DateTime.now())}',
          ),
          const SizedBox(height: 8),
          ...widget.tasks!.map((t) => _TaskCard(
            task: t,
            isExpanded: _expandedId == t.id,
            onToggle: () => _toggleExpand(t.id),
            onComplete: () => _completeTask(t.id),
            onDelete: () => _deleteTask(t.id),
          )),
        ],
        if (hasReservations) ...[
          if (hasTasks) const SizedBox(height: 8),
          _SectionHeader(label: 'Rezervasyonlar'),
          const SizedBox(height: 8),
          ...widget.reservations!.map((r) => _ReservationCard(
            res: r,
            isExpanded: _expandedId == r.id,
            onToggle: () => _toggleExpand(r.id),
            onDelete: () => _deleteTask(r.id),
          )),
        ],
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _AppColors.border),
            ),
            child: const Icon(Icons.inbox_outlined, size: 36, color: _AppColors.text3),
          ),
          const SizedBox(height: 20),
          Text(
            'Henüz bir kayıt bulunmuyor',
            style: GoogleFonts.dmSans(
              fontSize: 16,
              color: _AppColors.text3,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Task Card ─────────────────────────────────────────────────────────────────
class _TaskCard extends StatelessWidget {
  final TaskModel task;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onComplete;
  final VoidCallback onDelete;

  const _TaskCard({
    required this.task,
    required this.isExpanded,
    required this.onToggle,
    required this.onComplete,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = EventMapper.getColor(task.type);
    final icon  = EventMapper.getIcon(task.type);
    final isCompleted = task.status == 'completed';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _AppColors.border),
        boxShadow: isExpanded
            ? [
                BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 24, offset: const Offset(0, 8)),
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6,  offset: const Offset(0, 2)),
              ]
            : [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4)),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            InkWell(
              onTap: onToggle,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _IconBubble(color: color, icon: icon),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: GoogleFonts.dmSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isCompleted ? _AppColors.text3 : _AppColors.text1,
                              decoration: isCompleted ? TextDecoration.lineThrough : null,
                              decorationColor: _AppColors.text3,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              _TimeBadge(time: DateFormat('HH:mm').format(task.startDate ?? DateTime.now())),
                              const SizedBox(width: 6),
                              _PriorityPill(priority: task.priority, isCompleted: isCompleted),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isCompleted)
                      const Icon(Icons.check_circle_rounded, color: _AppColors.accentGreen, size: 22)
                    else
                      _ChevronIcon(isOpen: isExpanded),
                  ],
                ),
              ),
            ),
            // Detail
            AnimatedSize(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeInOut,
              child: isExpanded
                  ? _TaskDetail(task: task, onComplete: onComplete, onDelete: onDelete)
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskDetail extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onComplete;
  final VoidCallback onDelete;

  const _TaskDetail({required this.task, required this.onComplete, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isCompleted = task.status == 'completed';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1, color: _AppColors.border),
          const SizedBox(height: 14),
          _DetailRow(
            icon: Icons.calendar_month_rounded,
            label: 'Tarih',
            value: _trDate(task.startDate ?? DateTime.now()),
          ),
          const SizedBox(height: 8),
          _DetailRow(
            icon: Icons.star_outline_rounded,
            label: 'Öncelik',
            value: task.priority.toUpperCase(),
          ),
          if (task.description != null && task.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _DescriptionBox(text: task.description!),
          ] else
            const SizedBox(height: 14),
          Row(
            children: [
              if (!isCompleted) ...[
                Expanded(child: _CompleteButton(onTap: onComplete)),
                const SizedBox(width: 8),
              ],
              Expanded(child: _DeleteButton(label: 'Sil', onTap: onDelete)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Reservation Card ──────────────────────────────────────────────────────────
class _ReservationCard extends StatelessWidget {
  final ReservationModel res;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _ReservationCard({
    required this.res,
    required this.isExpanded,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = EventMapper.getColor(res.category);
    final icon  = EventMapper.getIcon(res.category);
    final isCompleted = res.status == 'completed' ||
        (res.endDate != null && DateTime.now().isAfter(res.endDate!));

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _AppColors.border),
        boxShadow: isExpanded
            ? [
                BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 24, offset: const Offset(0, 8)),
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6,  offset: const Offset(0, 2)),
              ]
            : [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4)),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: onToggle,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _IconBubble(color: color, icon: icon),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            res.title,
                            style: GoogleFonts.dmSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: _AppColors.text1,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              res.category,
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isCompleted)
                      const Icon(Icons.check_circle_rounded, color: _AppColors.accentGreen, size: 22)
                    else
                      _ChevronIcon(isOpen: isExpanded),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeInOut,
              child: isExpanded
                  ? _ReservationDetail(res: res, onDelete: onDelete)
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReservationDetail extends StatelessWidget {
  final ReservationModel res;
  final VoidCallback onDelete;

  const _ReservationDetail({required this.res, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1, color: _AppColors.border),
          const SizedBox(height: 14),
          _DetailRow(
            icon: Icons.login_rounded,
            label: 'Başlangıç',
            value: _fmt(res.startDate),
          ),
          const SizedBox(height: 8),
          _DetailRow(
            icon: Icons.logout_rounded,
            label: 'Bitiş',
            value: _fmt(res.endDate),
          ),
          if (res.details.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'REZERVASYON BİLGİLERİ',
              style: GoogleFonts.dmSans(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: _AppColors.text3,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: res.details.entries
                  .map((e) => _InfoTag(keyName: e.key, value: e.value.toString()))
                  .toList(),
            ),
            const SizedBox(height: 14),
          ] else
            const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: _DeleteButton(label: 'Rezervasyonu Sil', onTap: onDelete),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime? dt) => _trDateTime(dt);
}

// ─── Small Reusable Widgets ────────────────────────────────────────────────────

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _AppColors.border),
        ),
        child: const Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: _AppColors.text1),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.dmSans(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: _AppColors.text3,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _IconBubble extends StatelessWidget {
  final Color color;
  final IconData icon;
  const _IconBubble({required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

class _TimeBadge extends StatelessWidget {
  final String time;
  const _TimeBadge({required this.time});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.schedule_rounded, size: 12, color: _AppColors.text3),
        const SizedBox(width: 3),
        Text(
          time,
          style: GoogleFonts.dmSans(fontSize: 12, color: _AppColors.text3, fontWeight: FontWeight.w400),
        ),
      ],
    );
  }
}

class _PriorityPill extends StatelessWidget {
  final String priority;
  final bool isCompleted;
  const _PriorityPill({required this.priority, required this.isCompleted});

  @override
  Widget build(BuildContext context) {
    if (isCompleted) {
      return _pill('Tamamlandı', _AppColors.pillDoneBg, _AppColors.pillDoneText);
    }
    switch (priority.toLowerCase()) {
      case 'high':
      case 'yüksek':
        return _pill('Yüksek', _AppColors.pillHighBg, _AppColors.pillHighText);
      case 'medium':
      case 'orta':
        return _pill('Orta', _AppColors.pillMedBg, _AppColors.pillMedText);
      default:
        return _pill('Düşük', _AppColors.pillLowBg, _AppColors.pillLowText);
    }
  }

  Widget _pill(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(
        label,
        style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}

class _ChevronIcon extends StatelessWidget {
  final bool isOpen;
  const _ChevronIcon({required this.isOpen});

  @override
  Widget build(BuildContext context) {
    return AnimatedRotation(
      turns: isOpen ? 0.5 : 0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: _AppColors.background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: _AppColors.text3),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: _AppColors.text3),
        const SizedBox(width: 8),
        SizedBox(
          width: 68,
          child: Text(
            '$label:',
            style: GoogleFonts.dmSans(fontSize: 12, color: _AppColors.text2),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _AppColors.text1,
            ),
          ),
        ),
      ],
    );
  }
}

class _DescriptionBox extends StatelessWidget {
  final String text;
  const _DescriptionBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _AppColors.descBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AÇIKLAMA',
            style: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: _AppColors.text3,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: GoogleFonts.dmSans(fontSize: 13, color: _AppColors.text2, height: 1.6),
          ),
        ],
      ),
    );
  }
}

class _InfoTag extends StatelessWidget {
  final String keyName;
  final String value;
  const _InfoTag({required this.keyName, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _AppColors.tagBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _AppColors.border),
      ),
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.dmSans(fontSize: 11, color: _AppColors.text1),
          children: [
            TextSpan(
              text: '$keyName: ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(color: _AppColors.text2, fontWeight: FontWeight.w400),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompleteButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CompleteButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: _AppColors.accentGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      child: const Text('Tamamla'),
    );
  }
}

class _DeleteButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _DeleteButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: _AppColors.deleteBtnBorder, width: 1.5),
        foregroundColor: _AppColors.accentRed,
        padding: const EdgeInsets.symmetric(vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      child: Text(label),
    );
  }
}

// ─── Delete Dialog ─────────────────────────────────────────────────────────────
class _DeleteDialog extends StatelessWidget {
  const _DeleteDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _AppColors.surfaceWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _AppColors.pillHighBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.delete_outline_rounded, color: _AppColors.accentRed, size: 22),
            ),
            const SizedBox(height: 16),
            Text(
              'Silme Onayı',
              style: GoogleFonts.dmSerifDisplay(fontSize: 20, color: _AppColors.text1),
            ),
            const SizedBox(height: 8),
            Text(
              'Bu öğeyi kalıcı olarak silmek istediğinize emin misiniz?',
              style: GoogleFonts.dmSans(fontSize: 14, color: _AppColors.text2, height: 1.5),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _AppColors.border),
                      foregroundColor: _AppColors.text2,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      textStyle: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    child: const Text('Vazgeç'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _AppColors.accentRed,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      textStyle: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    child: const Text('Sil'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}